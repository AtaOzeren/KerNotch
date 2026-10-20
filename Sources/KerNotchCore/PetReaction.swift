import Foundation

/// Something the pet does in answer to what happens on the island: a hop when
/// the island opens, a call for the user when an agent asks something, a
/// celebration when one finishes.
///
/// A reaction is a few seconds long and played where the pet is. It never
/// leaves the stage it is given, so an icon beside the pet is never walked
/// through, and it ends on the floor — sitting, or standing to set off — so the
/// routine that follows can take over from it without a jump.
///
/// Each species plays a reaction its own way (`PetSpecies.reactions(to:)`
/// says which it knows): a dog barks for attention, a penguin squawks, a cow
/// moos.
public enum PetReaction: String, CaseIterable, Sendable {
    /// The island opening: startled into a hop, with an exclamation mark.
    case surprisedHop
    /// The island opening: off with its edge to the new corner — a dog runs,
    /// a penguin slides.
    case runAlongEdge
    /// The island opening: lying down to watch for as long as it stays open.
    case lieAndWatch
    /// The island opening: a flipper waved hello.
    case wave
    /// The island opening: a moo of hello.
    case moo
    /// The island closing: shaking itself off, water flying.
    case shakeOff
    /// The island closing: a long stretch, then a yawn.
    case stretch
    /// The island closing: relief — a dog pants, a penguin fans itself, a cow
    /// chews its cud.
    case relief
    /// The island closing: combing its chest feathers with its beak.
    case preen
    /// The island closing: a fly buzzing round, swatted at with the tail.
    case swatFly
    /// An agent asking something: ear flopped, head tilted, question mark.
    case headTilt
    /// An agent asking something: calling the user — a dog barks, a penguin
    /// squawks, a cow moos.
    case barkForAttention
    /// An agent asking something: a paw or a flipper raised, like a hand.
    case raisePaw
    /// An agent asking something: looking one way, then the other.
    case lookAround
    /// An agent asking something: a foot tapping, impatiently.
    case tapFoot
    /// An agent asking something: the bell on its collar rung for the user.
    case ringBell
    /// An agent failing: lying down with its ears back under a rain cloud.
    case sulk
    /// An agent failing: seeing stars.
    case dazed
    /// An agent failing: keeling over, then shaking it off.
    case faint
    /// An agent failing: feet gone from under it, flat on its back.
    case slip
    /// An agent failing: steam snorted from the nostrils, a hoof stamped.
    case snort
    /// An agent finishing: hopping for joy among sparkles — a cow bucks.
    case celebrate
    /// An agent finishing: tearing back and forth across the flank.
    case zoomies
    /// An agent finishing: catching a treat that drops from above — a bone,
    /// a fish or a daisy.
    case treat
    /// An agent finishing: a dance.
    case dance
    /// A countdown running out: calling out at the bell.
    case timerAlarm
    /// The charger going in: a jolt, a hop and a dash.
    case powerRush
    /// The pointer moving onto the pet: delight, with hearts.
    case petted
    /// The pointer moving onto the pet: eyes shut with delight and a soft
    /// moo, with hearts.
    case happyMoo
    /// The CPU watchdog's notice: too hot, with a bead of sweat.
    case sweat
    /// The CPU watchdog's notice: fanning itself with its tail.
    case coolOff
    /// An agent out of quota: a yawn, then off to sleep until it is back.
    case dozeOff

    /// Whether the reaction needs the whole flank to run in. Beside an icon
    /// there is one place, and the pet reacts in it or not at all.
    var needsRoom: Bool {
        self == .zoomies || self == .runAlongEdge
    }
}

/// Something that happened, which the pet may answer with a reaction.
public enum PetMoment: Hashable, CaseIterable, Sendable {
    case islandOpened
    case islandClosed
    case agentAsked
    case agentFailed
    case quotaExhausted
    case agentCompleted
    case timerExpired
    case chargerConnected
    case cpuStrained
    case petted

    /// How much the moment matters: a reaction to a moment that matters as much
    /// or more cuts in on one already playing, anything less is let go.
    public var urgency: PetUrgency {
        switch self {
        case .agentAsked, .agentFailed, .quotaExhausted: .pressing
        case .agentCompleted, .timerExpired: .notable
        case .chargerConnected, .cpuStrained: .passing
        case .islandOpened, .islandClosed, .petted: .casual
        }
    }

    /// The island opening and closing happen whenever the pointer passes over
    /// it, so they are answered only now and then; everything else is news.
    var isOccasional: Bool {
        self == .islandOpened || self == .islandClosed
    }
}

/// How much a moment matters to the pet.
public enum PetUrgency: Int, Comparable, Sendable {
    case casual
    case passing
    case notable
    case pressing

    public static func < (lhs: PetUrgency, rhs: PetUrgency) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
