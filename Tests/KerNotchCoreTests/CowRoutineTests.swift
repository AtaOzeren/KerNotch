import Foundation
import Testing

@testable import KerNotchCore

/// What the cow does between reactions.
@Suite("Cow moods")
struct CowMoodTests {
    private static let geometry = IslandPet.cow.stageGeometry()
    private static let home = PetPose(position: 6, facing: .right, frame: .sit)

    private static func routine(
        _ mood: PetMood,
        on stage: PetStage = .roaming,
        from pose: PetPose = home,
        askingStyle: PetReaction? = nil,
        pastime: PetPastime? = nil,
        napDelay: TimeInterval? = nil
    ) -> PetRoutine {
        PetRoutine(
            stage: stage,
            from: pose,
            geometry: geometry,
            direction: PetDirection(
                species: .cow,
                mood: mood,
                askingStyle: askingStyle,
                pastime: pastime,
                napDelay: napDelay
            )
        )
    }

    /// Every mood, and every way the cow has of spending it.
    private static let moods: [(PetMood, PetPastime?, PetReaction?)] = [
        (.calm, nil, nil), (.listening, .nodding, nil), (.listening, .swaying, nil), (.digging, .typing, nil),
        (.digging, .fillingPail, nil), (.onCall, nil, nil), (.napping, nil, nil), (.asking, nil, .barkForAttention),
        (.asking, nil, .ringBell),
    ]

    @Test("every mood's loop comes back round seamlessly", arguments: moods)
    func loopsCloseSeamlessly(mood: PetMood, pastime: PetPastime?, style: PetReaction?) throws {
        for stage in [PetStage.roaming, .resting] {
            let loop = try #require(Self.routine(mood, on: stage, askingStyle: style, pastime: pastime).loop)

            #expect(loop.keyframes.last.map { $0.time < loop.duration } == true)
            #expect(loop.lastPose.position == loop.firstPose.position)
            #expect(loop.lastPose.facing == loop.firstPose.facing)
            #expect(loop.lastPose.lift == 0)
            for track in loop.effects {
                #expect(track.keyframes.first?.time == 0)
                #expect(track.keyframes.allSatisfy { $0.time <= loop.duration })
                #expect(track.keyframes.last?.point == nil)
            }
        }
    }

    @Test("a mood never takes the cow off its place beside an icon", arguments: moods)
    func moodsStayInTheRestingPlace(mood: PetMood, pastime: PetPastime?, style: PetReaction?) throws {
        let loop = try #require(Self.routine(mood, on: .resting, askingStyle: style, pastime: pastime).loop)

        #expect(loop.keyframes.allSatisfy { $0.pose.position == Self.geometry.restingPosition })
    }

    @Test(
        "each way of spending a mood has its own look",
        arguments: [
            (PetPastime.nodding, PetFrame.sitNod, PetEffect.note), (.swaying, .swayLeft, .note),
            (.typing, .typingLift, nil), (.fillingPail, .pailFull, .milk),
        ] as [(PetPastime, PetFrame, PetEffect?)]
    )
    func pastimesLookTheirPart(pastime: PetPastime, frame: PetFrame, effect: PetEffect?) throws {
        let mood: PetMood = [.nodding, .swaying].contains(pastime) ? .listening : .digging
        let loop = try #require(Self.routine(mood, pastime: pastime).loop)

        #expect(loop.keyframes.contains { $0.pose.frame == frame })
        if let effect {
            #expect(loop.effects.contains { $0.effect == effect })
        }
    }

    @Test("at work the laptop or the pail never leaves", arguments: [PetPastime.typing, .fillingPail])
    func workStaysOut(pastime: PetPastime) throws {
        let loop = try #require(Self.routine(.digging, pastime: pastime).loop)
        let props: Set<PetFrame> = [
            .typing, .typingLift, .typingBlink, .pailLow, .pailHalf, .pailFull, .pailBeam, .pailBlink, .pailNudge,
        ]

        #expect(loop.keyframes.allSatisfy { props.contains($0.pose.frame) })
    }

    @Test("the pail fills up, spills over and is nudged empty again")
    func pailFillsAndEmpties() throws {
        let frames = try #require(Self.routine(.digging, pastime: .fillingPail).loop).keyframes.map(\.pose.frame)
        let half = try #require(frames.firstIndex(of: .pailHalf))
        let full = try #require(frames.firstIndex(of: .pailFull))
        let nudge = try #require(frames.firstIndex(of: .pailNudge))

        #expect(frames.first == .pailLow)
        #expect(half < full)
        #expect(full < nudge)
        #expect(frames.last == .pailLow)
    }

    /// The pail stands under the muzzle: a drop drawn over the cow would be
    /// milk running down its face, so every drop keeps to empty pixels or
    /// falls into the pail itself.
    @Test("the milk never falls over the cow")
    func milkKeepsClearOfTheCow() throws {
        let loop = try #require(Self.routine(.digging, pastime: .fillingPail).loop)
        let sheet = PetSpriteSheet.cow
        let art = PetEffectArt.standard
        let drops = loop.effects.filter { $0.effect == .milk }
        let pailColors = ["W", "G", "g"].compactMap { sheet.palette[$0] }

        #expect(drops.isEmpty == false)
        for track in drops {
            for keyframe in track.keyframes {
                guard let point = keyframe.point else { continue }
                let pose = loop.pose(at: keyframe.time)
                let pailColumns = pose.facing == .right ? 24..<32 : 0..<8
                let left = (point.position - pose.position) * sheet.pixelsPerPoint
                let bottom = sheet.height - point.height * sheet.pixelsPerPoint
                for row in bottom - art.pixelHeight(of: .milk)..<bottom {
                    for column in left..<left + art.pixelWidth(of: .milk) {
                        let covered = sheet.color(of: pose.frame, facing: pose.facing, column: column, row: row)
                        let intoThePail = pailColumns.contains(column) && row >= 19 && (covered.map(pailColors.contains) ?? false)
                        #expect(covered == nil || intoThePail, "a drop over the \(pose.frame) at \(keyframe.time)")
                    }
                }
            }
        }
    }

    @Test(
        "while an agent waits there is always a question mark",
        arguments: PetSpecies.cow.reactions(to: .agentAsked)
    )
    func askingKeepsTheQuestion(style: PetReaction) throws {
        let loop = try #require(Self.routine(.asking, askingStyle: style).loop)
        let questions = loop.effects.filter { $0.effect == .question }

        #expect(questions.isEmpty == false)
        for moment in stride(from: 0.05, to: loop.duration - 0.3, by: 0.1) where style != .barkForAttention {
            #expect(questions.contains { $0.point(at: moment) != nil }, "\(style) at \(moment)")
        }
    }

    @Test("an empty island's cow ambles about, meets a butterfly and a daisy now and then, then naps")
    func idleHasVisitorsThenANap() throws {
        let routine = Self.routine(.idle(since: 0), napDelay: 300)
        let loop = try #require(routine.loop)
        let idle = try #require(PetLoops.idleLoop(on: .roaming, in: Self.geometry, species: .cow))
        let firstSeen = { (effect: PetEffect) -> [Int] in
            routine.entrance.effects.filter { $0.effect == effect }
                .compactMap { $0.keyframes.first { $0.point != nil }.map { Int($0.time / 60) } }
        }

        #expect(loop.keyframes.allSatisfy { $0.pose.frame == .sleep })
        #expect(routine.entrance.duration >= 300)
        #expect(routine.entrance.duration < 300 + idle.duration + 10)
        #expect(routine.entrance.keyframes.filter { $0.time < 299 }.allSatisfy { $0.pose.frame.posture != .lying })
        // A visitor about every forty-five seconds, not all the time.
        #expect((3...5).contains(firstSeen(.butterfly).count))
        #expect((3...5).contains(firstSeen(.daisy).count))
        #expect(routine.stillPose?.frame.isSitting == true)
    }

    @Test("beside an icon the island is never empty, so no visitors come")
    func noVisitorsBesideAnIcon() throws {
        let loop = try #require(PetLoops.idleLoop(on: .resting, in: Self.geometry, species: .cow))

        #expect(loop.effects.contains { $0.effect == .butterfly || $0.effect == .daisy } == false)
    }

    @Test("a butterfly on its nose has the cow look at it cross-eyed")
    func butterflyIsWatched() throws {
        let idle = try #require(PetLoops.idleLoop(on: .roaming, in: Self.geometry, species: .cow))
        let butterfly = try #require(idle.effects.first { $0.effect == .butterfly })
        let landed = try #require(
            butterfly.keyframes.first { $0.point == PetPoint(position: idle.firstPose.position + CowAnchors.noseLying.inset, height: CowAnchors.noseLying.height) })

        #expect(idle.pose(at: landed.time).frame == .noseLook)
    }

    @Test("woken by something arriving, the cow stretches and yawns")
    func wakingIsAStretch() {
        let routine = Self.routine(.calm, from: PetPose(position: 6, facing: .right, frame: .sleep))
        let frames = routine.entrance.keyframes.map(\.pose.frame)

        #expect(frames.contains(.playBow))
        #expect(frames.contains(.yawn))
        #expect(routine.entrance.lastPose == routine.loop?.firstPose)
    }

    @Test("the stage's loops lie for most of their length", arguments: [PetStage.roaming, .resting])
    func stageLoopsMostlyLie(stage: PetStage) throws {
        let loop = try #require(CowLoops.stageLoop(on: stage, in: Self.geometry))
        let boundaries = loop.keyframes.map(\.time) + [loop.duration]
        let sitting = zip(loop.keyframes, boundaries.dropFirst())
            .filter { $0.0.pose.frame.isSitting }
            .reduce(0) { $0 + ($1.1 - $1.0.time) }

        #expect(sitting / loop.duration > 0.5)
    }
}

/// Everything the cow is ever shown doing is drawn on its sheet.
@Suite("Cow repertoire")
struct CowRepertoireTests {
    private static let geometry = IslandPet.cow.stageGeometry()

    private static func frames(of timeline: PetTimeline?) -> Set<PetFrame> {
        Set(timeline?.keyframes.map(\.pose.frame) ?? [])
    }

    @Test("every pose of every reaction and loop is on the cow's sheet")
    func everyPoseIsDrawn() {
        var shown: Set<PetFrame> = []
        for reaction in PetSpecies.cow.repertoire {
            for pose in PetReactionTests.startingPoses(for: .cow) {
                let routine = PetReactionTests.routine(reaction, of: .cow, on: .roaming, from: pose)
                shown.formUnion(Self.frames(of: routine.entrance))
                shown.formUnion(Self.frames(of: routine.loop))
            }
        }
        let moods: [(PetMood, PetPastime?, PetReaction?)] = [
            (.listening, .nodding, nil), (.listening, .swaying, nil), (.digging, .typing, nil),
            (.digging, .fillingPail, nil), (.onCall, nil, nil), (.napping, nil, nil),
            (.asking, nil, .barkForAttention), (.asking, nil, .ringBell), (.idle(since: 0), nil, nil),
        ]
        for (mood, pastime, style) in moods {
            for stage in [PetStage.roaming, .resting] {
                let routine = PetRoutine(
                    stage: stage,
                    from: PetPose(position: 6, facing: .right, frame: .sleep),
                    geometry: Self.geometry,
                    direction: PetDirection(
                        species: .cow,
                        mood: mood,
                        askingStyle: style,
                        pastime: pastime,
                        napDelay: mood == .idle(since: 0) ? 300 : nil
                    )
                )
                shown.formUnion(Self.frames(of: routine.entrance))
                shown.formUnion(Self.frames(of: routine.loop))
            }
        }

        let undrawn = shown.filter { PetSpriteSheet.cow.frames[$0] == nil }
        #expect(undrawn.isEmpty, "shown but not drawn: \(undrawn)")
    }

    /// Every frame the cow's sheet draws is one it is shown in: a pose drawn
    /// but never played would be art nobody sees.
    @Test("every pose on the cow's sheet is played somewhere")
    func everyDrawnPoseIsShown() {
        var shown: Set<PetFrame> = []
        let geometries = [Self.geometry, IslandPet.cow.openIslandStageGeometry(stripWidth: 85)]
        for geometry in geometries {
            for reaction in PetSpecies.cow.repertoire {
                for pose in PetReactionTests.startingPoses(for: .cow) {
                    let routine = PetReactionTests.routine(
                        reaction, of: .cow, on: .roaming, from: pose, geometry: geometry)
                    shown.formUnion(Self.frames(of: routine.entrance))
                }
            }
        }
        for (mood, pastime) in [
            (PetMood.listening, PetPastime.nodding), (.listening, .swaying), (.digging, .typing),
            (.digging, .fillingPail),
        ] {
            let routine = PetRoutine(
                stage: .roaming,
                from: PetPose(position: 3, facing: .right, frame: .sit),
                geometry: Self.geometry,
                direction: PetDirection(species: .cow, mood: mood, pastime: pastime)
            )
            shown.formUnion(Self.frames(of: routine.loop))
        }
        for loop in [
            PetLoops.idleLoop(on: .roaming, in: Self.geometry, species: .cow),
            PetLoops.onCall(at: PetPose(position: 3, facing: .right, frame: .sit), spriteWidth: 16, species: .cow),
            PetLoops.watching(at: PetPose(position: 3, facing: .right, frame: .sit), spriteWidth: 16, species: .cow),
            CowLoops.asking(style: .ringBell, at: PetPose(position: 3, facing: .right, frame: .sit), spriteWidth: 16),
        ] {
            shown.formUnion(Self.frames(of: loop))
        }

        let unplayed = Set(PetSpriteSheet.cow.frames.keys).subtracting(shown)
        #expect(unplayed.isEmpty, "drawn but never played: \(unplayed)")
    }
}

/// How the tracker picks among the cow's ways of spending a mood.
@Suite("Cow pastimes")
struct CowPastimeTests {
    private static let geometry = IslandPet.cow.stageGeometry()

    private static func loopFrames(_ tracker: PetRoutineTracker) -> Set<PetFrame> {
        Set(tracker.performance?.routine.loop?.keyframes.map(\.pose.frame) ?? [])
    }

    @Test("music and work are each spent both ways, one picked each time the mood begins")
    func bothWaysComeUp() {
        var sawTyping = false
        var sawPail = false
        var sawNodding = false
        var sawSwaying = false
        for seed in UInt64(1)...30 {
            var dice = PetDice(seed: seed)
            var tracker = PetRoutineTracker(species: .cow)
            tracker.follow(PetScene(stage: .roaming, geometry: Self.geometry, mood: .digging), at: 0, dice: &dice)
            let working = Self.loopFrames(tracker)
            sawTyping = sawTyping || working.contains(.typing)
            sawPail = sawPail || working.contains(.pailLow)
            tracker.follow(PetScene(stage: .roaming, geometry: Self.geometry, mood: .listening), at: 30, dice: &dice)
            let listening = Self.loopFrames(tracker)
            sawNodding = sawNodding || listening.contains(.sitNod)
            sawSwaying = sawSwaying || listening.contains(.swayLeft)
        }

        #expect(sawTyping && sawPail)
        #expect(sawNodding && sawSwaying)
    }

    @Test("a cow reacts only with its own reactions")
    func reactsWithItsOwn() throws {
        var dice = PetDice(seed: 5)
        var tracker = PetRoutineTracker(species: .cow)
        tracker.follow(PetScene(stage: .roaming, geometry: Self.geometry), at: 0, dice: &dice)
        for (index, moment) in [PetMoment.agentAsked, .agentFailed, .agentCompleted, .timerExpired].enumerated() {
            tracker.follow(
                PetScene(stage: .roaming, geometry: Self.geometry),
                moments: [moment],
                at: Double(index + 1) * 100,
                dice: &dice
            )
            let frames = Set(try #require(tracker.performance).routine.entrance.keyframes.map(\.pose.frame))
            #expect(frames.allSatisfy { PetSpriteSheet.cow.frames[$0] != nil }, "\(moment)")
        }
    }

    @Test("forgotten, a cow is still a cow")
    func forgettingKeepsTheSpecies() {
        var tracker = PetRoutineTracker(species: .cow)
        tracker.forget()

        #expect(tracker.species == .cow)
    }
}
