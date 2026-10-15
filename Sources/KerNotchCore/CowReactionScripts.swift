import Foundation

/// Where effects sit beside the cow. Standing, its head is where the dog's is,
/// so the dog's anchors serve; lying with its legs folded, the head is three
/// and a half points lower.
enum CowAnchors {
    /// The lines of a moo, past the muzzle at the mouth.
    static let mooLines = PetEffectAnchor(effect: .barkLines, inset: 16, height: 4)
    static let mooLinesLying = PetEffectAnchor(effect: .barkLines, inset: 16, height: 1)
    static let notes = PetEffectAnchor(effect: .note, inset: 15, height: 9)
    static let notesLying = PetEffectAnchor(effect: .note, inset: 15, height: 6)
    /// The middle of the head of the cow lying, which stars circle.
    static let headLying = PetEffectAnchor(effect: .star, inset: 11, height: 10)
    /// The head of a cow keeled over on its back.
    static let headOnTheFloor = PetEffectAnchor(effect: .star, inset: 12, height: 6)
    static let heartsLying = PetEffectAnchor(effect: .smallHeart, inset: 11, height: 9)
    /// The back of the head, where sweat runs down.
    static let backOfHead = PetEffectAnchor(effect: .sweat, inset: 9, height: 10)
    static let backOfHeadLying = PetEffectAnchor(effect: .sweat, inset: 9, height: 7)
    /// The flared nostrils of a snorting cow.
    static let nostrils = PetEffectAnchor(effect: .steam, inset: 15, height: 6)
    /// Either side of the bell on its collar.
    static let bellFront = PetEffectAnchor(effect: .jingle, inset: 12, height: 4)
    static let bellBack = PetEffectAnchor(effect: .jingle, inset: 8, height: 4)
    /// The open mouth of a cow looking up, where a daisy dropping is caught.
    static let mouth = PetEffectAnchor(effect: .daisy, inset: 13, height: 6)
    /// On top of the muzzle of the cow lying, where a butterfly lands.
    static let noseLying = PetEffectAnchor(effect: .butterfly, inset: 13, height: 5)
    /// The rump, which a fly buzzes round.
    static let rump = PetEffectAnchor(effect: .fly, inset: 2, height: 9)
    /// In the grass before the muzzle of a grazing cow.
    static let grass = PetEffectAnchor(effect: .daisy, inset: 16, height: 0)
}

extension PetCall {
    /// Standing, mooing past the muzzle.
    static let moo = PetCall(resting: .stand, calling: .moo, lines: CowAnchors.mooLines)
}

/// The cow's reactions: the same moments as the others', answered with a
/// moo, a bell, a tail and a buck.
extension PetChoreographer {
    /// A reaction outside the cow's repertoire plays nothing.
    mutating func performAsCow(_ reaction: PetReaction, on stage: PetStage, in geometry: PetStageGeometry) {
        switch reaction {
        case .surprisedHop, .runAlongEdge, .lieAndWatch, .moo, .shakeOff, .stretch, .relief, .swatFly:
            performCowIslandReaction(reaction, in: geometry)
        case .barkForAttention, .ringBell:
            performCowQuestion(reaction)
        case .dazed, .faint, .sulk, .snort, .celebrate, .treat, .dance:
            performCowAgentNews(reaction)
        case .timerAlarm, .powerRush, .petted, .happyMoo, .sweat, .coolOff, .dozeOff:
            performCowNews(reaction, on: stage, in: geometry)
        case .wave, .preen, .headTilt, .raisePaw, .lookAround, .tapFoot, .slip, .zoomies:
            return
        }
    }

    private mutating func performCowIslandReaction(_ reaction: PetReaction, in geometry: PetStageGeometry) {
        switch reaction {
        case .surprisedHop:
            standUp()
            hop(height: 4, carrying: .exclamation)
            sitDown()
            alternate([.sitWag, .sit], every: 0.15, times: 2)
        case .runAlongEdge:
            runAlongEdge(in: geometry)
        case .lieAndWatch:
            lieDown()
            hold(0.4)
        case .moo:
            mooHello()
        case .shakeOff:
            shakeOff()
        case .stretch:
            stretchAndYawn()
        case .relief:
            sitDown()
            alternate([.sitChewA, .sitChewB], every: 0.2, times: 5)
            show(.sitBlink)
            hold(0.13)
            show(.sitBeam)
            hold(0.5)
            show(.sit)
            hold(0.2)
        case .swatFly:
            swatFly()
        default:
            return
        }
    }

    private mutating func performCowQuestion(_ reaction: PetReaction) {
        switch reaction {
        case .barkForAttention:
            callOut(.moo, times: 2, marking: .exclamation)
            askQuestion(for: 1.6)
            hold(1.6)
        case .ringBell:
            standUp()
            askQuestion(for: 2.6)
            ringBell(for: 1.8)
            show(.stand)
            hold(0.8)
        default:
            return
        }
    }

    private mutating func performCowAgentNews(_ reaction: PetReaction) {
        switch reaction {
        case .dazed:
            seeStars(around: CowAnchors.headLying)
        case .faint:
            keelOver()
        case .sulk:
            sulk()
        case .snort:
            snort()
        case .celebrate:
            buckForJoy()
        case .treat:
            catchDaisy()
        case .dance:
            danceWithTheBell()
        default:
            return
        }
    }

    private mutating func performCowNews(_ reaction: PetReaction, on stage: PetStage, in geometry: PetStageGeometry) {
        switch reaction {
        case .timerAlarm:
            standUp()
            let bell = besidePet(.bell)
            let ringing = (0..<20).map { step in
                PetPoint(position: bell.position + (step.isMultiple(of: 2) ? 0 : 1), height: bell.height)
            }
            emit(.bell, at: ringing, every: Self.frameInterval)
            callOut(.moo, times: 3)
        case .powerRush:
            powerRush(canRun: stage == .roaming, in: geometry)
        case .petted:
            sitDown()
            floatHearts(from: CowAnchors.heartsLying)
            alternate([.sitWag, .sit], every: 0.13, times: 6)
            show(.sitBlink)
            hold(0.5)
            show(.sit)
            hold(0.3)
        case .happyMoo:
            sitDown()
            floatHearts(from: CowAnchors.heartsLying)
            show(.sitBeam)
            hold(0.4)
            emit(.barkLines, at: besidePet(CowAnchors.mooLinesLying), for: 0.8, mirrored: pose.facing == .left)
            show(.sitMoo)
            hold(0.8)
            show(.sitBeam)
            hold(0.5)
            show(.sit)
            hold(0.3)
        case .sweat:
            sitDown()
            sweatDrops(from: CowAnchors.backOfHeadLying)
            alternate([.sitPant, .sit], every: 0.2, times: 6)
        case .coolOff:
            standUp()
            sweatDrops(from: CowAnchors.backOfHead)
            alternate([.tailSwishA, .tailSwishB], every: 0.13, times: 8)
            show(.stand)
            hold(0.2)
        case .dozeOff:
            dozeOff()
        default:
            return
        }
    }

    /// Up on its feet for a long moo, notes rising, then a beam.
    private mutating func mooHello() {
        standUp()
        hold(0.2)
        emit(.barkLines, at: besidePet(CowAnchors.mooLines), for: 0.8, mirrored: pose.facing == .left)
        emitNotes(from: CowAnchors.notes, startingAt: [0.1, 0.5])
        show(.moo)
        hold(0.8)
        show(.stand)
        hold(0.2)
        show(.beam)
        hold(0.5)
        show(.stand)
        hold(0.2)
        sitDown()
    }

    /// A fly buzzing round its rump, swatted at with the tail until it gives
    /// up and flies off.
    private mutating func swatFly() {
        standUp()
        let rump = CowAnchors.rump
        var path: [PetEffectStep] = []
        var moment = 0.0
        while moment < 2.4 {
            let angle = 2 * Double.pi * moment / 0.6
            path.append(
                PetEffectStep(
                    after: moment,
                    point: besidePet(
                        .fly,
                        inset: rump.inset + Int((3 * cos(angle)).rounded()),
                        height: rump.height + Int((1.5 * sin(angle)).rounded())
                    )
                )
            )
            moment += Self.frameInterval
        }
        for step in 1...5 {
            path.append(
                PetEffectStep(
                    after: moment + Double(step - 1) * Self.frameInterval,
                    point: besidePet(.fly, inset: rump.inset - step, height: rump.height + step)
                )
            )
        }
        emit(.fly, along: path, lasting: moment + 5 * Self.frameInterval)
        hold(0.4)
        alternate([.tailSwishA, .stand, .tailSwishB, .stand], every: 0.12, times: 4)
        show(.standBlink)
        hold(0.15)
        show(.stand)
        hold(0.4)
        sitDown()
    }

    /// The head swung from side to side, the bell ringing out either side of
    /// it, for about `seconds`.
    mutating func ringBell(for seconds: TimeInterval) {
        let stroke = 0.15
        let strokes = Int((seconds / (2 * stroke)).rounded())
        emit(
            .jingle,
            along: twinkling(at: besidePet(CowAnchors.bellFront), for: seconds, flashing: stroke),
            lasting: seconds,
            mirrored: pose.facing == .left
        )
        emit(
            .jingle,
            along: twinkling(at: besidePet(CowAnchors.bellBack), for: seconds, flashing: stroke, after: stroke),
            lasting: seconds,
            mirrored: pose.facing == .right
        )
        alternate([.bellLeft, .bellRight], every: stroke, times: strokes)
    }

    /// Wobbling, then over onto its back with its legs in the air, stars round
    /// its head; up again shaking it off.
    private mutating func keelOver() {
        standUp()
        show(.stand)
        hold(0.3)
        alternate([.shakeLeft, .shakeRight], every: 0.12, times: 2)
        show(.crouch)
        hold(Self.crouchDuration)
        show(.onBack)
        emit(.puff, at: besidePet(.puff, inset: 2, height: 0), for: 0.3)
        emit(.dust, at: besidePet(.dust, inset: 7, height: 0), for: 0.2)
        emit(.puff, at: besidePet(.puff, inset: 15, height: 0), for: 0.3)
        hold(0.2)
        circleStars(around: CowAnchors.headOnTheFloor, for: 1.5)
        hold(1.6)
        standUp()
        alternate([.shakeLeft, .shakeRight], every: 0.1, times: 2)
        show(.stand)
        hold(0.3)
        sitDown()
    }

    /// Head down and frowning, steam snorted from the nostrils and a hoof
    /// stamped, twice over.
    private mutating func snort() {
        standUp()
        show(.snort)
        for start in [0.1, 1.1] {
            for (index, offset) in [0.0, 0.2].enumerated() {
                emit(
                    .steam,
                    along: (0..<5).map { step in
                        PetEffectStep(
                            after: start + offset + Double(step) * 0.08,
                            point: besidePet(
                                .steam,
                                inset: CowAnchors.nostrils.inset + step,
                                height: CowAnchors.nostrils.height + index + step / 2
                            )
                        )
                    },
                    lasting: start + offset + 0.4
                )
            }
        }
        hold(0.5)
        alternate([.stompUp, .snort], every: 0.15, times: 2)
        hold(0.3)
        alternate([.stompUp, .snort], every: 0.15, times: 2)
        hold(0.3)
        show(.stand)
        hold(0.3)
        sitDown()
    }

    /// Sparkles going off, a hop and a buck, twice over.
    private mutating func buckForJoy() {
        sparkle(for: 2.4)
        for _ in 0..<2 {
            hop(height: 3)
            show(.buck)
            hold(0.3)
            show(.stand)
            hold(0.1)
        }
        sitDown()
        alternate([.sitWag, .sit], every: 0.13, times: 2)
    }

    /// Looks up, and a daisy drops into its open mouth. It chews it happily,
    /// hearts rising.
    private mutating func catchDaisy() {
        standUp()
        let mouth = besidePet(CowAnchors.mouth)
        emit(
            .daisy,
            at: [10, 8, 6, 4, 2, 1, 0].map { PetPoint(position: mouth.position, height: mouth.height + $0) },
            every: 0.5 / 7
        )
        show(.lookUp)
        hold(0.5)
        show(.holdDaisy)
        hold(0.3)
        alternate([.holdDaisyChew, .holdDaisy], every: 0.18, times: 3)
        emit(
            .smallHeart,
            along: drifting(.smallHeart, fromInset: 11, height: 12, steps: 5, every: 0.14),
            lasting: 0.7
        )
        show(.beam)
        hold(0.6)
        show(.stand)
        hold(0.3)
    }

    /// Stepping from hoof to hoof, the bell ringing and sparkles going off.
    private mutating func danceWithTheBell() {
        standUp()
        for (index, sparkle) in [
            PetEffectAnchor(effect: .sparkle, inset: -3, height: 10),
            PetEffectAnchor(effect: .sparkle, inset: 16, height: 13),
        ].enumerated() {
            emit(
                sparkle.effect,
                along: twinkling(at: besidePet(sparkle), for: 2.2, flashing: 0.2, after: Double(index) * 0.1),
                lasting: 2.2
            )
        }
        emit(
            .jingle,
            along: twinkling(at: besidePet(CowAnchors.bellFront), for: 2.2, flashing: 0.18),
            lasting: 2.2,
            mirrored: pose.facing == .left
        )
        alternate([.danceLeft, .beam, .danceRight, .beam], every: 0.18, times: 3)
        show(.beam)
        hold(0.4)
        show(.stand)
        hold(0.3)
    }

    /// Notes drifting up from `anchor`, one from each of `starts` seconds on.
    mutating func emitNotes(from anchor: PetEffectAnchor, startingAt starts: [TimeInterval]) {
        for start in starts {
            emit(
                .note,
                along: drifting(.note, fromInset: anchor.inset, height: anchor.height, steps: 6, every: 0.18, after: start),
                lasting: start + 1.08
            )
        }
    }
}
