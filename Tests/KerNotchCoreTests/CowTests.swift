import Foundation
import Testing

@testable import KerNotchCore

@Suite("Cow art")
struct CowArtTests {
    private static let sheet = PetSpriteSheet.cow

    @Test("the art is drawn two pixels to a point, 16 × 12 points on screen like the others")
    func artIsRetinaDense() {
        #expect(Self.sheet.pixelsPerPoint == 2)
        #expect(Self.sheet.width == 32)
        #expect(Self.sheet.height == 24)
        #expect(Self.sheet.pointWidth == PetSpriteSheet.shiba.pointWidth)
        #expect(Self.sheet.pointHeight == PetSpriteSheet.shiba.pointHeight)
    }

    /// The head is one block in every standing and sitting pose, so a blink
    /// touches nothing but the eye.
    @Test(
        "a blink shuts the eye and changes nothing else",
        arguments: [
            (PetFrame.stand, PetFrame.standBlink, 0), (.sit, .sitBlink, 7), (.typing, .typingBlink, 7),
            (.pailLow, .pailBlink, 7), (.lie, .lieBlink, 9),
        ]
    )
    func blinkOnlyShutsTheEye(open: PetFrame, shut: PetFrame, headTop: Int) {
        let changed = Self.changedPixels(from: open, to: shut)

        #expect(changed.isEmpty == false)
        #expect(changed.allSatisfy { (23...25).contains($0.column) && (headTop + 4...headTop + 5).contains($0.row) })
    }

    /// The island is black, so the patches are slate and their rim lit: a
    /// black patch on the outline would bite a hole in the cow.
    @Test("the patches stand out from the island's black")
    func patchesAreNotBlack() throws {
        let patch = try #require(Self.sheet.palette["K"])
        let rim = try #require(Self.sheet.palette["H"])

        #expect(Int(patch.red) + Int(patch.green) + Int(patch.blue) > 3 * 0x28)
        #expect(Int(rim.red) + Int(rim.green) + Int(rim.blue) > Int(patch.red) + Int(patch.green) + Int(patch.blue))
    }

    @Test("walking, the legs move and the body does not", arguments: [PetFrame.strideA, .strideB])
    func strideMovesOnlyTheLegs(stride: PetFrame) {
        let changed = Self.changedPixels(from: .stand, to: stride)

        #expect(changed.isEmpty == false)
        #expect(changed.allSatisfy { $0.row >= 19 })
    }

    /// Its sit is lying with the legs folded under, so it is lower than the
    /// standing cow, and lying to watch or asleep lower still.
    @Test("resting, the cow lies low with its legs folded under it")
    func restingIsLyingDown() throws {
        let top = { (frame: PetFrame) -> Int? in
            (0..<Self.sheet.height).first { row in
                (0..<Self.sheet.width).contains { Self.sheet.color(of: frame, facing: .right, column: $0, row: row) != nil }
            }
        }
        let standing = try #require(top(.stand))
        let sitting = try #require(top(.sit))
        let lying = try #require(top(.lie))

        #expect(sitting > standing)
        #expect(lying > sitting)
        #expect(PetFrame.sit.posture == .sitting)
    }

    /// The pail is drawn as an outline, so the milk shows filling it from the
    /// bottom up.
    @Test("the pail fills from the bottom up")
    func pailFillsFromTheBottom() {
        let white = Self.sheet.palette["W"]
        let milk = { (frame: PetFrame) -> [Int] in
            (19..<Self.sheet.height).map { row in
                (24..<Self.sheet.width).filter { Self.sheet.color(of: frame, facing: .right, column: $0, row: row) == white }
                    .count
            }
        }
        let low = milk(.pailLow)
        let half = milk(.pailHalf)
        let full = milk(.pailFull)

        #expect(low.reduce(0, +) < half.reduce(0, +))
        #expect(half.reduce(0, +) < full.reduce(0, +))
        #expect(low[3] > 0)
        #expect(low[1] == 0)
    }

    private static func changedPixels(from before: PetFrame, to after: PetFrame) -> [(column: Int, row: Int)] {
        var changed: [(column: Int, row: Int)] = []
        for row in 0..<sheet.height {
            for column in 0..<sheet.width
            where sheet.color(of: before, facing: .right, column: column, row: row)
                != sheet.color(of: after, facing: .right, column: column, row: row)
            {
                changed.append((column, row))
            }
        }
        return changed
    }
}

@Suite("Cow movement")
struct CowMovementTests {
    private static let standing = PetPose(position: 0, facing: .right, frame: .stand)

    @Test("in a hurry the cow runs with a skip every few strides, a point at a time")
    func hurryingIsABound() {
        var choreographer = PetChoreographer(startingAt: Self.standing, spriteWidth: 16, species: .cow)
        choreographer.travel(to: 30, gait: .run)
        let timeline = choreographer.timeline()

        #expect(timeline.keyframes.contains { $0.pose.frame == .hop && $0.pose.lift > 0 })
        #expect(timeline.keyframes.contains { $0.pose.frame == .strideA && $0.pose.lift == 0 })
        #expect(timeline.keyframes.contains { $0.pose.frame == .slide } == false)
        #expect(timeline.keyframes.allSatisfy { ($0.pose.lift > 0) == ($0.pose.frame == .hop) })
        #expect(PetChoreographerTests.largestStep(in: timeline) == 1)
        #expect(timeline.lastPose == PetPose(position: 30, facing: .right, frame: .stand))
    }

    /// A skip is only begun where it lands before the end, so a dash of any
    /// length arrives on the ground.
    @Test("a dash of any length ends on the ground", arguments: Array(1...40))
    func boundingLandsBeforeTheEnd(distance: Int) {
        var choreographer = PetChoreographer(startingAt: Self.standing, spriteWidth: 16, species: .cow)
        choreographer.travel(to: -distance, gait: .run)
        let timeline = choreographer.timeline()

        #expect(timeline.keyframes.last { $0.pose.position == -distance }?.pose.lift == 0)
        #expect(timeline.lastPose == PetPose(position: -distance, facing: .left, frame: .stand))
        #expect(timeline.keyframes.allSatisfy { ($0.pose.lift > 0) == ($0.pose.frame == .hop) })
    }

    @Test("strolling the cow walks on its hooves, never skipping")
    func walkingNeverSkips() {
        var choreographer = PetChoreographer(startingAt: Self.standing, spriteWidth: 16, species: .cow)
        choreographer.walk(to: 30)
        let frames = Set(choreographer.timeline().keyframes.map(\.pose.frame))

        #expect(frames.isSuperset(of: [.strideA, .strideB, .stand]))
        #expect(frames.contains(.hop) == false)
    }

    /// Its sit is already on the floor: it lies down from there and sits back
    /// up without getting up in between.
    @Test("from its sit the cow lies down and sits back up without kneeling")
    func lyingDownStaysOnTheFloor() {
        var choreographer = PetChoreographer(
            startingAt: PetPose(position: 3, facing: .right, frame: .sit), spriteWidth: 16, species: .cow)
        choreographer.hold(0.5)
        choreographer.lieDown()
        choreographer.hold(0.5)
        choreographer.sitDown()

        #expect(choreographer.timeline().keyframes.map(\.pose.frame) == [.sit, .lie, .sit])
    }

    @Test("getting up the cow comes up off its knees")
    func standingUpKneelsFirst() {
        var choreographer = PetChoreographer(
            startingAt: PetPose(position: 3, facing: .right, frame: .sit), spriteWidth: 16, species: .cow)
        choreographer.hold(0.5)
        choreographer.standUp()

        #expect(choreographer.timeline().keyframes.map(\.pose.frame) == [.sit, .crouch, .stand])
    }

    @Test("a dog lying down from its sit still goes through the crouch")
    func dogsStillCrouch() {
        var choreographer = PetChoreographer(
            startingAt: PetPose(position: 3, facing: .right, frame: .sit), spriteWidth: 16, species: .dog)
        choreographer.hold(0.5)
        choreographer.lieDown()

        #expect(choreographer.timeline().keyframes.map(\.pose.frame) == [.sit, .crouch, .lie])
    }

    /// An icon arriving beside the pet has a place of its own: the pet only
    /// steps to the middle of its place, with nothing to hurry for.
    @Test("an icon arriving beside it has the cow step aside, not run", arguments: [0, 6])
    func iconArrivingIsAStep(position: Int) {
        let geometry = IslandPet.cow.stageGeometry()
        let routine = PetRoutine(
            stage: .resting,
            from: PetPose(position: position, facing: .right, frame: .stand),
            geometry: geometry,
            species: .cow
        )
        let frames = Set(routine.entrance.keyframes.map(\.pose.frame))

        #expect(frames.contains(.hop) == false)
        #expect(frames.contains(.strideA) || frames.contains(.strideB))
        #expect(routine.entrance.lastPose.position == geometry.restingPosition)
    }

    @Test("leaving a full flank the cow bounds off the island")
    func leavingIsABound() {
        let geometry = IslandPet.cow.openIslandStageGeometry(stripWidth: 85)
        let routine = PetRoutine(
            stage: .away,
            from: PetPose(position: 40, facing: .right, frame: .sit),
            geometry: geometry,
            species: .cow
        )

        #expect(routine.entrance.keyframes.contains { $0.pose.frame == .hop && $0.pose.lift > 0 })
        #expect(routine.entrance.lastPose.position == geometry.offstagePosition)
        #expect(routine.entrance.lastPose.lift == 0)
    }
}

/// The cow's own ways of answering the island's moments.
@Suite("Cow reactions")
struct CowReactionTests {
    private static let home = PetPose(position: 1, facing: .right, frame: .sit)

    private static func routine(_ reaction: PetReaction, from pose: PetPose = home) -> PetRoutine {
        PetReactionTests.routine(reaction, of: .cow, on: .roaming, from: pose)
    }

    @Test(
        "each reaction shows what it is about",
        arguments: [
            (PetReaction.surprisedHop, PetEffect.exclamation), (.moo, .barkLines), (.moo, .note),
            (.shakeOff, .droplet), (.swatFly, .fly), (.barkForAttention, .barkLines), (.barkForAttention, .question),
            (.ringBell, .question), (.ringBell, .jingle), (.dazed, .star), (.faint, .star), (.faint, .puff),
            (.sulk, .cloud), (.snort, .steam), (.celebrate, .sparkle), (.treat, .daisy), (.treat, .smallHeart),
            (.dance, .sparkle), (.dance, .jingle), (.timerAlarm, .bell), (.powerRush, .bolt), (.petted, .smallHeart),
            (.happyMoo, .smallHeart), (.happyMoo, .barkLines), (.sweat, .sweat), (.coolOff, .sweat),
        ]
    )
    func reactionsShowTheirEffect(reaction: PetReaction, effect: PetEffect) {
        let effects = Self.routine(reaction).entrance.effects

        #expect(effects.contains { $0.effect == effect })
    }

    @Test(
        "each reaction is drawn in its own poses",
        arguments: [
            (PetReaction.surprisedHop, PetFrame.hop), (.runAlongEdge, .strideA), (.lieAndWatch, .lie), (.moo, .moo),
            (.shakeOff, .shakeLeft), (.stretch, .playBow), (.stretch, .yawn), (.relief, .sitChewA),
            (.relief, .sitChewB), (.swatFly, .tailSwishA), (.barkForAttention, .moo), (.ringBell, .bellLeft),
            (.ringBell, .bellRight), (.dazed, .dazed), (.faint, .onBack), (.sulk, .lieSad), (.snort, .snort),
            (.snort, .stompUp), (.celebrate, .buck), (.treat, .lookUp), (.treat, .holdDaisy), (.treat, .holdDaisyChew),
            (.dance, .danceLeft), (.timerAlarm, .moo), (.powerRush, .hop), (.petted, .sitWag), (.happyMoo, .sitMoo),
            (.sweat, .sitPant), (.coolOff, .tailSwishB), (.dozeOff, .sleep),
        ]
    )
    func reactionsUseTheirPoses(reaction: PetReaction, frame: PetFrame) {
        let frames = Self.routine(reaction).entrance.keyframes.map(\.pose.frame)

        #expect(frames.contains(frame))
    }

    @Test(
        "the cow's own reactions are only the cow's",
        arguments: [PetReaction.moo, .swatFly, .ringBell, .snort, .happyMoo, .coolOff]
    )
    func cowOnlyReactions(reaction: PetReaction) {
        #expect(PetSpecies.cow.repertoire.contains(reaction))
        #expect(PetSpecies.dog.repertoire.contains(reaction) == false)
        #expect(PetSpecies.penguin.repertoire.contains(reaction) == false)
    }

    @Test(
        "the others' own reactions are not the cow's",
        arguments: [PetReaction.headTilt, .raisePaw, .lookAround, .zoomies, .wave, .preen, .tapFoot, .slip]
    )
    func othersOnlyReactions(reaction: PetReaction) {
        #expect(PetSpecies.cow.repertoire.contains(reaction) == false)
    }

    @Test("the cow answers every moment the way the user picked")
    func repertoireIsThePicked() {
        #expect(PetSpecies.cow.reactions(to: .islandOpened) == [.surprisedHop, .runAlongEdge, .lieAndWatch, .moo])
        #expect(PetSpecies.cow.reactions(to: .islandClosed) == [.shakeOff, .stretch, .relief, .swatFly])
        #expect(PetSpecies.cow.reactions(to: .agentAsked) == [.barkForAttention, .ringBell])
        #expect(PetSpecies.cow.reactions(to: .agentFailed) == [.dazed, .faint, .sulk, .snort])
        #expect(PetSpecies.cow.reactions(to: .agentCompleted) == [.celebrate, .treat, .dance])
        #expect(PetSpecies.cow.reactions(to: .cpuStrained) == [.sweat, .coolOff])
        #expect(PetSpecies.cow.reactions(to: .petted) == [.petted, .happyMoo])
    }

    @Test(
        "the question mark hangs over the cow's head, whichever way it faces",
        arguments: [PetFacing.right, .left]
    )
    func questionOverTheHead(facing: PetFacing) throws {
        let position = 3
        let routine = Self.routine(.ringBell, from: PetPose(position: position, facing: facing, frame: .stand))
        let question = try #require(routine.entrance.effects.first { $0.effect == .question })
        let mark = try #require(question.keyframes.compactMap(\.point).first)
        let sheet = PetSpriteSheet.cow
        let crown = (0..<sheet.width).filter { sheet.color(of: .stand, facing: facing, column: $0, row: 0) != nil }
        let crownLeft = try #require(crown.min())
        let crownRight = try #require(crown.max())
        let crownMiddle = Double(position) + Double(crownLeft + crownRight) / 2 / Double(sheet.pixelsPerPoint)
        let markMiddle = Double(mark.position) + 1.5

        #expect(abs(markMiddle - crownMiddle) <= 2)
        #expect(mark.height > sheet.pointHeight)
    }

    @Test("a moo's lines point the way the cow faces")
    func mooLinesAreMirroredFacingLeft() throws {
        let left = Self.routine(.barkForAttention, from: PetPose(position: 3, facing: .left, frame: .stand))
        let lines = try #require(left.entrance.effects.first { $0.effect == .barkLines })

        #expect(lines.isMirrored)
    }

    @Test("the bell rings out on both sides of it", arguments: [PetFacing.right, .left])
    func bellRingsBothWays(facing: PetFacing) {
        let routine = Self.routine(.ringBell, from: PetPose(position: 3, facing: facing, frame: .stand))
        let jingles = routine.entrance.effects.filter { $0.effect == .jingle }

        #expect(jingles.count == 2)
        #expect(Set(jingles.map(\.isMirrored)) == [false, true])
    }

    /// In its one place on the pill the dash is as long as the place allows;
    /// on the open island's strip it goes the full twelve points, skipping.
    @Test("with the flank to itself a charging cow runs out and back, as far as its stage allows")
    func powerRushRunsOutAndBack() throws {
        for geometry in [PetReactionTests.geometry, PetReactionTests.openGeometry] {
            let routine = PetReactionTests.routine(.powerRush, of: .cow, on: .roaming, from: Self.home, geometry: geometry)
            let end = try #require(routine.reactionEnd)
            let reaction = routine.entrance.keyframes.filter { $0.time <= end }

            #expect(
                reaction.map(\.pose.position).max() == min(Self.home.position + 12, geometry.roamingRange.upperBound))
            #expect(routine.entrance.pose(at: end).position == Self.home.position)
        }
    }

    @Test("both ways of being petted, and of keeping cool, come up")
    func pettingAndCoolingBothWays() {
        let geometry = IslandPet.cow.stageGeometry()
        var played: Set<PetReaction> = []
        for seed in UInt64(1)...30 {
            var dice = PetDice(seed: seed)
            var tracker = PetRoutineTracker(species: .cow)
            tracker.follow(PetScene(stage: .roaming, geometry: geometry), at: 0, dice: &dice)
            for (index, moment) in [PetMoment.petted, .cpuStrained].enumerated() {
                tracker.follow(
                    PetScene(stage: .roaming, geometry: geometry),
                    moments: [moment],
                    at: Double(index + 1) * 100,
                    dice: &dice
                )
                let frames = Set(tracker.performance?.routine.entrance.keyframes.map(\.pose.frame) ?? [])
                if frames.contains(.sitMoo) { played.insert(.happyMoo) }
                if frames.contains(.sitWag) { played.insert(.petted) }
                if frames.contains(.sitPant) { played.insert(.sweat) }
                if frames.contains(.tailSwishA) { played.insert(.coolOff) }
            }
        }

        #expect(played == [.petted, .happyMoo, .sweat, .coolOff])
    }
}
