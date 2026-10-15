import Foundation

/// The cow's loops: the stage's own — ambling about its place, or lying beside
/// an icon — and one for each way it spends a mood. The moods every pet spends
/// alike — asleep, on a call, lying to watch — are in `PetLoops`.
///
/// Like the others', every loop ends in the pose it began with, and the
/// stage's loops lie for most of their length.
enum CowLoops {
    static func stageLoop(on stage: PetStage, in geometry: PetStageGeometry) -> PetTimeline? {
        switch stage {
        case .roaming: roaming(in: geometry)
        case .resting: resting(in: geometry)
        case .away: nil
        }
    }

    /// The flank's loop twice, then a butterfly landing on its nose; twice
    /// more, then a daisy found in the grass: about eighty seconds, so one or
    /// the other comes about every forty seconds while the island stays empty. Beside an icon the island is never empty, so there it is
    /// the stage's own loop.
    static func idleLoop(on stage: PetStage, in geometry: PetStageGeometry) -> PetTimeline? {
        guard stage == .roaming else { return stageLoop(on: stage, in: geometry) }
        let stroll = roaming(in: geometry)
        var choreographer = PetChoreographer(
            startingAt: stroll.firstPose,
            spriteWidth: geometry.spriteWidth,
            species: .cow
        )
        for visit in [watchButterfly, eatDaisy] {
            for _ in 0..<2 {
                choreographer.append(stroll)
                choreographer.show(stroll.firstPose.frame)
            }
            visit(&choreographer)
        }
        return choreographer.loop()
    }

    /// Waiting on the user with a question mark over its head, and every few
    /// seconds the call it chose when the question came: a moo, or the bell.
    static func asking(style: PetReaction, at home: PetPose, spriteWidth: Int) -> PetTimeline {
        var choreographer = PetChoreographer(startingAt: standing(at: home), spriteWidth: spriteWidth, species: .cow)
        switch style {
        case .ringBell:
            let length = 6.0
            choreographer.askQuestion(for: length)
            choreographer.hold(2)
            choreographer.ringBell(for: 1.2)
            choreographer.show(.stand)
            // Ends exactly where the question mark does, so it never blinks
            // out as the loop comes round.
            choreographer.hold(length - choreographer.time)
        default:
            choreographer.askQuestion(for: 2.5)
            choreographer.hold(2.5)
            choreographer.callOut(.moo, times: 2)
            choreographer.askQuestion(for: 2.5)
            choreographer.hold(2.5)
        }
        return choreographer.loop()
    }

    /// Music: nodding along where it lies, or swaying on its feet, with notes
    /// rising.
    static func listening(_ pastime: PetPastime, at home: PetPose, spriteWidth: Int) -> PetTimeline {
        switch pastime {
        case .swaying:
            var choreographer = PetChoreographer(
                startingAt: standing(at: home),
                spriteWidth: spriteWidth,
                species: .cow
            )
            choreographer.hold(1.5)
            choreographer.show(.standBlink)
            choreographer.hold(0.15)
            choreographer.show(.stand)
            choreographer.hold(0.5)
            choreographer.emitNotes(from: CowAnchors.notes, startingAt: [0.1, 0.9, 1.7])
            choreographer.alternate([.swayLeft, .beam, .swayRight, .beam], every: 0.22, times: 3)
            choreographer.show(.stand)
            choreographer.hold(0.5)
            return choreographer.loop()
        case .nodding, .typing, .fishing, .fillingPail:
            var choreographer = PetChoreographer(startingAt: home, spriteWidth: spriteWidth, species: .cow)
            choreographer.sit(for: 3, beats: [PetBeat(offset: 1.5, gesture: .blink)])
            choreographer.emitNotes(from: CowAnchors.notesLying, startingAt: [0.1, 0.9])
            choreographer.alternate([.sitNod, .sit], every: 0.25, times: 4)
            choreographer.show(.sitBeam)
            choreographer.hold(0.3)
            choreographer.show(.sit)
            choreographer.hold(0.2)
            return choreographer.loop()
        }
    }

    /// An agent at work: the cow typing at a laptop of its own, or a pail
    /// beside it filling with milk.
    static func working(_ pastime: PetPastime, at home: PetPose, spriteWidth: Int) -> PetTimeline {
        switch pastime {
        case .fillingPail:
            fillingPail(at: home, spriteWidth: spriteWidth)
        case .typing, .nodding, .swaying, .fishing:
            typing(at: home, spriteWidth: spriteWidth)
        }
    }

    /// Bursts of typing with a hoof, a pause to read what came back, a blink.
    private static func typing(at home: PetPose, spriteWidth: Int) -> PetTimeline {
        var choreographer = PetChoreographer(
            startingAt: PetPose(position: home.position, facing: home.facing, frame: .typing),
            spriteWidth: spriteWidth,
            species: .cow
        )
        choreographer.alternate([.typingLift, .typing], every: 0.13, times: 6)
        choreographer.hold(1.2)
        choreographer.show(.typingBlink)
        choreographer.hold(0.15)
        choreographer.show(.typing)
        choreographer.hold(0.8)
        choreographer.alternate([.typingLift, .typing], every: 0.13, times: 4)
        choreographer.hold(1.5)
        return choreographer.loop()
    }

    /// Milk dripping into the pail beside it until it is full and spills over;
    /// the cow beams at it, nudges it empty, and it fills again. The pail
    /// stands under the muzzle, so the drops come down just past it and fall
    /// in from the side, and spill out on the far side: anything falling
    /// straight down would run over the cow's face.
    private static func fillingPail(at home: PetPose, spriteWidth: Int) -> PetTimeline {
        var choreographer = PetChoreographer(
            startingAt: PetPose(position: home.position, facing: home.facing, frame: .pailLow),
            spriteWidth: spriteWidth,
            species: .cow
        )
        for start in stride(from: 0.4, to: 4.6, by: 0.6) {
            choreographer.emit(
                .milk,
                along: falling(along: dripPath, from: start, beside: choreographer),
                lasting: start + Double(dripPath.count) * PetChoreographer.frameInterval
            )
        }
        choreographer.hold(1.2)
        choreographer.show(.pailBlink)
        choreographer.hold(0.15)
        choreographer.show(.pailLow)
        choreographer.hold(0.6)
        choreographer.show(.pailHalf)
        choreographer.hold(1.6)
        choreographer.show(.pailFull)
        choreographer.hold(0.6)
        spill(&choreographer)
        choreographer.show(.pailBeam)
        choreographer.hold(0.8)
        choreographer.show(.pailFull)
        choreographer.hold(0.3)
        choreographer.show(.pailNudge)
        spill(&choreographer)
        choreographer.hold(0.4)
        choreographer.show(.pailLow)
        choreographer.hold(0.8)
        return choreographer.loop()
    }

    /// Where a drop of milk falls, in points from the sprite's left edge and
    /// up from the floor: down past the muzzle, then in over the pail's rim.
    private static let dripPath = [(17, 8), (17, 6), (16, 4), (16, 3), (15, 2), (14, 1)]

    /// Where drops splash out over the pail's far rim, clear of the cow.
    private static let spillPaths = [
        [(16, 3), (17, 4), (18, 3), (19, 1), (19, 0)],
        [(16, 2), (17, 2), (18, 1), (18, 0)],
        [(16, 3), (18, 4), (19, 3), (20, 2), (21, 0)],
    ]

    private static func falling(
        along path: [(inset: Int, height: Int)],
        from start: TimeInterval,
        beside choreographer: PetChoreographer
    ) -> [PetEffectStep] {
        path.enumerated().map { step, point in
            PetEffectStep(
                after: start + Double(step) * PetChoreographer.frameInterval,
                point: choreographer.besidePet(.milk, inset: point.inset, height: point.height)
            )
        }
    }

    /// Drops of milk splashing out over the pail's rim.
    private static func spill(_ choreographer: inout PetChoreographer) {
        for (index, path) in spillPaths.enumerated() {
            let start = Double(index) * 0.08
            choreographer.emit(
                .milk,
                along: falling(along: path, from: start, beside: choreographer),
                lasting: start + Double(path.count) * PetChoreographer.frameInterval
            )
        }
    }

    /// About twenty seconds on the empty flank: lying most of it, an amble to
    /// each end, chewing the cud, a flick of the tail.
    static func roaming(in geometry: PetStageGeometry) -> PetTimeline {
        let home = PetPose(position: PetLoops.spot(0.18, in: geometry), facing: .right, frame: .sit)

        var choreographer = PetChoreographer(startingAt: home, spriteWidth: geometry.spriteWidth, species: .cow)
        choreographer.sit(
            for: 3.2,
            beats: [PetBeat(offset: 1.0, gesture: .blink), PetBeat(offset: 1.8, gesture: .chew)]
        )
        choreographer.walk(to: PetLoops.spot(1, in: geometry))
        choreographer.hold(0.4)
        choreographer.show(.standBlink)
        choreographer.hold(0.15)
        choreographer.show(.stand)
        choreographer.hold(0.3)
        swishTail(&choreographer, times: 2)
        choreographer.sit(
            for: 4.0,
            beats: [PetBeat(offset: 1.0, gesture: .wag), PetBeat(offset: 2.8, gesture: .blink)]
        )
        choreographer.walk(to: PetLoops.spot(0.35, in: geometry))
        choreographer.sit(for: 2.6, beats: [PetBeat(offset: 0.8, gesture: .chew)])
        choreographer.walk(to: PetLoops.spot(0, in: geometry))
        choreographer.hold(0.3)
        choreographer.turn(.right)
        choreographer.hold(0.3)
        choreographer.sit(
            for: 3.4,
            beats: [PetBeat(offset: 1.0, gesture: .blink), PetBeat(offset: 2.0, gesture: .chew)]
        )
        choreographer.walk(to: home.position)
        choreographer.sitDown()
        return choreographer.loop()
    }

    /// Beside a single icon, in the one place left: lying, and every quarter
    /// of a minute standing for a flick of the tail and a look back.
    static func resting(in geometry: PetStageGeometry) -> PetTimeline {
        let home = PetPose(position: geometry.restingPosition, facing: .right, frame: .sit)

        var choreographer = PetChoreographer(startingAt: home, spriteWidth: geometry.spriteWidth, species: .cow)
        choreographer.sit(
            for: 7.0,
            beats: [PetBeat(offset: 2.0, gesture: .blink), PetBeat(offset: 4.0, gesture: .chew)]
        )
        choreographer.standUp()
        choreographer.hold(0.4)
        swishTail(&choreographer, times: 2)
        choreographer.turn(.left)
        choreographer.hold(0.9)
        choreographer.show(.standBlink)
        choreographer.hold(0.15)
        choreographer.show(.stand)
        choreographer.hold(0.3)
        choreographer.turn(.right)
        choreographer.hold(0.3)
        choreographer.sit(
            for: 6.0,
            beats: [PetBeat(offset: 1.5, gesture: .wag), PetBeat(offset: 4.0, gesture: .blink)]
        )
        return choreographer.loop()
    }

    /// A butterfly fluttering down onto its nose; the cow looks at it
    /// cross-eyed until it flutters off again, then beams.
    private static func watchButterfly(_ choreographer: inout PetChoreographer) {
        choreographer.sitDown()
        let nose = CowAnchors.noseLying
        let arrival = [(2, 14), (4, 13), (6, 13), (7, 11), (9, 11), (10, 9), (12, 8), (12, 7), (13, 6), (13, 5)]
        let departure = [(14, 7), (15, 9), (15, 11), (17, 12), (18, 14), (20, 15)]
        var path: [PetEffectStep] = []
        for (step, (inset, height)) in arrival.enumerated() {
            path.append(
                PetEffectStep(
                    after: Double(step) * 0.12,
                    point: choreographer.besidePet(.butterfly, inset: inset, height: height)
                )
            )
        }
        let landed = Double(arrival.count) * 0.12
        let takeOff = landed + 1.4
        path.append(
            PetEffectStep(after: landed, point: choreographer.besidePet(.butterfly, inset: nose.inset, height: nose.height))
        )
        for (step, (inset, height)) in departure.enumerated() {
            path.append(
                PetEffectStep(
                    after: takeOff + Double(step) * 0.12,
                    point: choreographer.besidePet(.butterfly, inset: inset, height: height)
                )
            )
        }
        choreographer.emit(.butterfly, along: path, lasting: takeOff + Double(departure.count) * 0.12)
        choreographer.hold(landed - 0.3)
        choreographer.show(.noseLook)
        choreographer.hold(1.7)
        choreographer.show(.sit)
        choreographer.hold(0.4)
        choreographer.show(.sitBeam)
        choreographer.hold(0.6)
        choreographer.show(.sit)
        choreographer.hold(0.3)
    }

    /// A daisy in the grass before it: the cow gets up, crops it and chews it
    /// with its eyes shut, beams, and lies back down.
    private static func eatDaisy(_ choreographer: inout PetChoreographer) {
        choreographer.standUp()
        choreographer.emit(.daisy, at: choreographer.besidePet(CowAnchors.grass), for: 1.2)
        choreographer.hold(0.6)
        choreographer.show(.graze)
        choreographer.hold(0.6)
        choreographer.alternate([.grazeChew, .graze], every: 0.18, times: 3)
        choreographer.show(.stand)
        choreographer.hold(0.2)
        choreographer.show(.beam)
        choreographer.hold(0.6)
        choreographer.show(.stand)
        choreographer.hold(0.3)
        choreographer.sitDown()
    }

    /// A few flicks of the tail, standing.
    private static func swishTail(_ choreographer: inout PetChoreographer, times: Int) {
        choreographer.standUp()
        choreographer.alternate([.tailSwishA, .stand, .tailSwishB, .stand], every: 0.12, times: times)
        choreographer.hold(0.2)
    }

    private static func standing(at home: PetPose) -> PetPose {
        PetPose(position: home.position, facing: home.facing, frame: .stand)
    }
}
