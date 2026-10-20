/// Which animal the pet is, which decides how it moves and what it does: a dog
/// runs, barks and digs; a penguin slides on its belly, squawks and types; a
/// cow bounds along, moos and fills a pail.
///
/// They all answer the same moments on the island, mostly with reactions of
/// the same name played each in its own way — a dog celebrates with a wag, a
/// penguin with a flap, a cow with a buck — so what the island notices never
/// depends on which pet is on it.
public enum PetSpecies: String, CaseIterable, Sendable {
    case dog
    case penguin
    case cow

    public var displayName: String {
        switch self {
        case .dog: localized("Dog")
        case .penguin: localized("Penguin")
        case .cow: localized("Cow")
        }
    }

    /// The art this pet is drawn from.
    public var sprites: PetSpriteSheet {
        switch self {
        case .dog: .shiba
        case .penguin: .penguin
        case .cow: .cow
        }
    }

    /// The reactions this pet chooses between, at random, for `moment`.
    public func reactions(to moment: PetMoment) -> [PetReaction] {
        switch self {
        case .dog: Self.dogReactions(to: moment)
        case .penguin: Self.penguinReactions(to: moment)
        case .cow: Self.cowReactions(to: moment)
        }
    }

    /// Every reaction this pet ever plays.
    public var repertoire: [PetReaction] {
        PetReaction.allCases.filter { reaction in
            PetMoment.allCases.contains { reactions(to: $0).contains(reaction) }
        }
    }

    /// How it hurries — out of an icon's way, off the island.
    var hurry: PetHurry {
        switch self {
        case .dog: .run
        case .penguin: .slide
        case .cow: .bound
        }
    }

    /// Whether its sit is already down on the floor — a cow lies with its legs
    /// folded under it — so it lies down from there, and sits back up, without
    /// getting up first.
    var sitsOnTheFloor: Bool {
        self == .cow
    }

    /// The ways this pet knows of passing `mood`, one picked each time the
    /// mood begins; empty for a mood it spends only one way.
    func pastimes(for mood: PetMood) -> [PetPastime] {
        switch (self, mood) {
        case (.penguin, .listening), (.cow, .listening): [.nodding, .swaying]
        case (.penguin, .digging): [.typing, .fishing]
        case (.cow, .digging): [.typing, .fillingPail]
        default: []
        }
    }

    /// Where the question mark hangs while an agent waits: over the head.
    var questionAnchor: PetEffectAnchor {
        switch self {
        case .dog, .cow: .question
        case .penguin: PetEffectAnchor(effect: .question, inset: 6, height: 13)
        }
    }

    /// Where the Zs of a nap rise from: the sleeping head.
    var snoreAnchor: PetEffectAnchor {
        switch self {
        case .dog: PetEffectAnchor(effect: .smallZ, inset: 14, height: 8)
        case .penguin: PetEffectAnchor(effect: .smallZ, inset: 12, height: 6)
        case .cow: PetEffectAnchor(effect: .smallZ, inset: 14, height: 7)
        }
    }

    private static func dogReactions(to moment: PetMoment) -> [PetReaction] {
        switch moment {
        case .islandOpened: [.surprisedHop, .runAlongEdge, .lieAndWatch]
        case .islandClosed: [.shakeOff, .stretch, .relief]
        case .agentAsked: [.headTilt, .barkForAttention, .raisePaw, .lookAround]
        case .agentFailed: [.sulk, .dazed, .faint]
        case .quotaExhausted: [.dozeOff]
        case .agentCompleted: [.celebrate, .zoomies, .treat]
        case .timerExpired: [.timerAlarm]
        case .chargerConnected: [.powerRush]
        case .cpuStrained: [.sweat]
        case .petted: [.petted]
        }
    }

    private static func penguinReactions(to moment: PetMoment) -> [PetReaction] {
        switch moment {
        case .islandOpened: [.surprisedHop, .runAlongEdge, .lieAndWatch, .wave]
        case .islandClosed: [.shakeOff, .stretch, .relief, .preen]
        case .agentAsked: [.barkForAttention, .raisePaw, .tapFoot]
        case .agentFailed: [.dazed, .slip]
        case .quotaExhausted: [.dozeOff]
        case .agentCompleted: [.celebrate, .treat, .dance]
        case .timerExpired: [.timerAlarm]
        case .chargerConnected: [.powerRush]
        case .cpuStrained: [.sweat]
        case .petted: [.petted]
        }
    }

    private static func cowReactions(to moment: PetMoment) -> [PetReaction] {
        switch moment {
        case .islandOpened: [.surprisedHop, .runAlongEdge, .lieAndWatch, .moo]
        case .islandClosed: [.shakeOff, .stretch, .relief, .swatFly]
        case .agentAsked: [.barkForAttention, .ringBell]
        case .agentFailed: [.dazed, .faint, .sulk, .snort]
        case .quotaExhausted: [.dozeOff]
        case .agentCompleted: [.celebrate, .treat, .dance]
        case .timerExpired: [.timerAlarm]
        case .chargerConnected: [.powerRush]
        case .cpuStrained: [.sweat, .coolOff]
        case .petted: [.petted, .happyMoo]
        }
    }
}

/// How a pet moves when it hurries.
enum PetHurry: Sendable {
    /// On its feet, at a run.
    case run
    /// Down on its belly, sliding.
    case slide
    /// At a run with a skip every few strides.
    case bound
}

/// A way of spending a mood that lasts, for the moods a pet knows more than
/// one way of spending.
enum PetPastime: Equatable, Sendable {
    /// Music: nodding along where it sits.
    case nodding
    /// Music: swaying from foot to foot.
    case swaying
    /// An agent working: typing away at a laptop of its own.
    case typing
    /// An agent working: fishing through a hole in the ice.
    case fishing
    /// An agent working: a pail beside it filling with milk.
    case fillingPail
}
