/// The cow's pixel art: its palette, the blocks its frames are built from,
/// and the frames themselves.
///
/// A Holstein in profile with a chibi's big head: a white coat with dark
/// patches, a pink muzzle, short horns, a yellow tag in its ear and a bell on
/// a red collar. It rests the way cows do, lying with its legs folded under
/// it, and it goes down and gets up on its front knees.
///
/// `W` coat and `w` coat in shadow — the far legs, the belly. `K` the patches,
/// and `H` their rim where the light catches it: on the island's black a black
/// patch on the outline would bite a hole in the cow, so the patches are slate
/// and lit where they meet the edge. `k` eye, `P` muzzle and udder, `p` the
/// nostril, the mouth and the inside of the ear, `M` inside the open mouth,
/// `C` and `c` the horns, `Y` and `y` the bell and the ear tag, `r` the
/// collar, `h` the hooves. `G` and `g` are the grey of the headset, the laptop
/// and the pail, `S` the laptop's screen and `L` its prompt.
enum CowArt {
    static let palette: [Character: PetColor] = [
        "W": PetColor(hex: 0xF4F1EA),
        "w": PetColor(hex: 0xC9C6C0),
        "K": PetColor(hex: 0x3A3F4C),
        "H": PetColor(hex: 0x6A7388),
        "k": PetColor(hex: 0x0E0F12),
        "P": PetColor(hex: 0xF2A7B5),
        "p": PetColor(hex: 0xC96F83),
        "M": PetColor(hex: 0xB8475A),
        "C": PetColor(hex: 0xEEE3C4),
        "c": PetColor(hex: 0xB8A77E),
        "Y": PetColor(hex: 0xF8C02C),
        "y": PetColor(hex: 0xD98A16),
        "r": PetColor(hex: 0xC23B3B),
        "h": PetColor(hex: 0x7A6A5A),
        "G": PetColor(hex: 0xA7ADB5),
        "g": PetColor(hex: 0x646A72),
        "S": PetColor(hex: 0x122218),
        "L": PetColor(hex: 0x6BF08A),
    ]

    static let frames: [PetFrame: [String]] = [
        .stand: standing(head),
        .standBlink: standing(painting(head, blinkingEye)),
        .strideA: standing(head, legs: strideALegs),
        .strideB: standing(head, legs: strideBLegs),
        .shakeLeft: shaking(by: -1),
        .shakeRight: shaking(by: 1),
        .crouch: crouch,
        .hop: stamping(head, onto: emptyRows(6) + standingBody + hopLegs + emptyRows(3), column: 0, row: 0),
        .moo: standing(painting(head, openMouth)),
        .beam: standing(smilingHead),
        .lookUp: standing(painting(head, openMouth + eyeUp)),
        .holdDaisy: stamping(heldDaisy, onto: standing(smilingHead), column: 26, row: 9),
        .holdDaisyChew: stamping(
            heldDaisy, onto: standing(painting(smilingHead, chewingBack)), column: 25, row: 9),
        .snort: standing(angryHead, headTop: 1),
        .stompUp: standing(angryHead, headTop: 1, legs: stompingLegs),
        .graze: standing(Array(head.prefix(12)), headTop: 11),
        .grazeChew: standing(Array(painting(head, blinkingEye + chewingBack).prefix(12)), headTop: 11),
        .swayLeft: swaying(standing(smilingHead), by: -1),
        .swayRight: swaying(standing(smilingHead), by: 1),
        .danceLeft: swaying(standing(smilingHead, legs: stompingLegs), by: -1),
        .danceRight: swaying(standing(smilingHead, legs: strideALegs), by: 1),
        .tailSwishA: painting(stand, tailErased + tailUp),
        .tailSwishB: painting(stand, tailErased + tailFlicked),
        .bellLeft: standing(shifting(painting(head, bellSwungRight), by: -1)),
        .bellRight: standing(shifting(painting(head, bellSwungLeft), by: 1)),
        .buck: buck,
        .playBow: playBow,
        .sit: sitting(head),
        .sitBlink: sitting(painting(head, blinkingEye)),
        .sitNod: sitting(head, headTop: 8),
        .sitWag: sitting(head, body: tuckedBodyWagging),
        .sitBeam: sitting(smilingHead),
        .sitMoo: sitting(painting(smilingHead, openMouth)),
        .sitPant: sitting(painting(head, pantingMouth)),
        .sitChewA: sitting(painting(head, chewingBack)),
        .sitChewB: sitting(painting(head, chewingForward)),
        .yawn: sitting(painting(head, blinkingEye + yawningMouth)),
        .dazed: sitting(painting(head, crossedEye)),
        .earsBack: sitting(painting(head, droopingEar + blinkingEye), headTop: 8),
        .noseLook: sitting(painting(head, eyeOnTheNose)),
        .headset: sitting(wearingHeadset(head)),
        .headsetBlink: sitting(wearingHeadset(painting(head, blinkingEye))),
        .headsetNod: sitting(wearingHeadset(head), headTop: 8),
        .typing: typing(on: head, hoof: hoofOnTheKeys, screen: laptop),
        .typingLift: typing(on: head, hoof: hoofLifted, screen: laptopCursorOff),
        .typingBlink: typing(on: painting(head, blinkingEye), hoof: hoofOnTheKeys, screen: laptop),
        .pailLow: withPail(lowPail, beside: sitting(head)),
        .pailHalf: withPail(halfPail, beside: sitting(head)),
        .pailFull: withPail(fullPail, beside: sitting(head)),
        .pailBeam: withPail(fullPail, beside: sitting(smilingHead)),
        .pailBlink: withPail(lowPail, beside: sitting(painting(head, blinkingEye))),
        .pailNudge: withPail(lowPail, beside: sitting(painting(head, blinkingEye), headTop: 9)),
        .lie: sitting(head, headTop: 9),
        .lieBlink: sitting(painting(head, blinkingEye), headTop: 9),
        .sleep: sitting(painting(head, blinkingEye), headTop: 10),
        .lieSad: sitting(painting(head, droopingEar + blinkingEye), headTop: 10),
        .onBack: onBack,
    ]

    private static let stand = standing(head)
    private static let smilingHead = painting(head, smilingEyes)
    private static let angryHead = painting(head, angryFace)

    /// The head laid over the standing body, its top `headTop` rows down.
    private static func standing(
        _ head: [String],
        headTop: Int = 0,
        legs: [String] = standingLegs
    ) -> [String] {
        stamping(head, onto: emptyRows(6) + standingBody + legs, column: 0, row: headTop)
    }

    /// Lying with the legs folded under, the head up — the cow's sit.
    private static func sitting(_ head: [String], headTop: Int = 7, body: [String] = tuckedBody) -> [String] {
        stamping(head, onto: emptyRows(13) + body, column: 0, row: headTop)
    }

    /// Head and body with no legs under them: the start of every pose that
    /// tilts the cow.
    private static let upperBody = stamping(
        head, onto: emptyRows(6) + standingBody + emptyRows(7), column: 0, row: 0)

    /// The head and shoulders thrown a pixel one way, the back the other way:
    /// shaking the water off.
    private static func shaking(by columns: Int) -> [String] {
        stamping(
            shifting(head, by: columns),
            onto: shifting(emptyRows(6) + Array(standingBody.prefix(4)), by: -columns)
                + standingBody.dropFirst(4) + standingLegs,
            column: 0,
            row: 0
        )
    }

    /// The top of a standing pose leaning a pixel one way, the legs planted.
    private static func swaying(_ rows: [String], by columns: Int) -> [String] {
        shifting(Array(rows.prefix(15)), by: columns) + rows.dropFirst(15)
    }

    /// Down on its front knees, the rear still up: how a cow lies down and
    /// gets up.
    private static let crouch = stamping(
        foldedFrontLegs,
        onto: stamping(
            keeping(Array(standingLegs.dropFirst()), columns: 0..<10),
            onto: tilting(upperBody) { column in
                switch column {
                case ..<10: 1
                case ..<13: 2
                default: 4
                }
            },
            column: 0,
            row: 18
        ),
        column: 0,
        row: 21
    )

    /// Front legs stretched out along the floor, the rear up: the stretch on
    /// waking.
    private static let playBow = stamping(
        stretchedFrontLegs,
        onto: stamping(
            keeping(standingLegs, columns: 0..<10),
            onto: tilting(upperBody) { column in
                switch column {
                case ..<8: 0
                case ..<12: 1
                case ..<16: 3
                default: 5
                }
            },
            column: 0,
            row: 17
        ),
        column: 0,
        row: 22
    )

    /// Head down and the hind legs kicked out behind: a buck for joy.
    private static let buck = stamping(
        kickingHindLegs,
        onto: stamping(
            keeping(Array(standingLegs.dropFirst()), columns: 12..<32),
            onto: tilting(upperBody) { column in
                switch column {
                case ..<9: -3
                case ..<13: -1
                default: 1
                }
            },
            column: 0,
            row: 18
        ),
        column: 0,
        row: 12
    )

    /// Keeled over onto its back, legs in the air and the eye crossed out.
    private static let onBack = stamping(
        keeping(Array(painting(head, crossedEye).prefix(12)), columns: 13..<32),
        onto: emptyRows(6)
            + keeping(Array((emptyRows(6) + standingBody + standingLegs).reversed().prefix(18)), columns: 0..<22),
        column: 0,
        row: 12
    )

    private static func wearingHeadset(_ head: [String]) -> [String] {
        stamping(headset, onto: head, column: 0, row: 0)
    }

    private static func typing(on head: [String], hoof: [ArtPixel], screen: [String]) -> [String] {
        painting(stamping(screen, onto: sitting(head), column: 23, row: 19), hoof)
    }

    private static func withPail(_ pail: [String], beside rows: [String]) -> [String] {
        stamping(pail, onto: rows, column: 24, row: 19)
    }
}

extension CowArt: PetArtComposer {
    static let artWidth = 32
}

/// The head and the looks it takes. The head is one block — horns, ear,
/// face, muzzle and the bell under the chin — laid over every standing and
/// sitting pose, so the eye and the mouth are always at these pixels.
extension CowArt {
    static let head = [
        "....................cC.....Cc...",
        "...................HKKKWWWWWWW..",
        "..............HKK.HKKKKWWWWWWWW.",
        ".............YppKKKKKKWWWWWWWWW.",
        "..............KKKKKKKWWWkkWWWWW.",
        ".................HKKKWWWkkWWWWW.",
        "..................HKWWWWWWWWWWW.",
        "..................WWWWWWPPPPPPPP",
        "..................WWWWWPPPPPPpPP",
        "..................wWWWWPPPPPPPPP",
        "..................wWWWWPPpppppP.",
        "..................rrrrrPPPPPPP..",
        "...................rYyr.........",
        "....................YYy.........",
        ".....................y..........",
    ]

    /// The lid down over the eye for a moment.
    static let blinkingEye = [
        ArtPixel(column: 24, row: 4, key: "W"),
        ArtPixel(column: 25, row: 4, key: "W"),
        ArtPixel(column: 23, row: 5, key: "k"),
        ArtPixel(column: 24, row: 5, key: "k"),
        ArtPixel(column: 25, row: 5, key: "k"),
    ]

    /// The eye curved shut with delight.
    static let smilingEyes = [
        ArtPixel(column: 24, row: 4, key: "k"),
        ArtPixel(column: 25, row: 4, key: "k"),
        ArtPixel(column: 23, row: 5, key: "k"),
        ArtPixel(column: 24, row: 5, key: "W"),
        ArtPixel(column: 25, row: 5, key: "W"),
        ArtPixel(column: 26, row: 5, key: "k"),
    ]

    /// The eye crossed out, seeing stars.
    static let crossedEye = [
        ArtPixel(column: 23, row: 3, key: "k"),
        ArtPixel(column: 25, row: 3, key: "k"),
        ArtPixel(column: 24, row: 4, key: "k"),
        ArtPixel(column: 25, row: 4, key: "W"),
        ArtPixel(column: 23, row: 5, key: "k"),
        ArtPixel(column: 24, row: 5, key: "W"),
        ArtPixel(column: 25, row: 5, key: "k"),
    ]

    /// A frown over the eye and the nostrils flared.
    static let angryFace = [
        ArtPixel(column: 23, row: 3, key: "k"),
        ArtPixel(column: 24, row: 3, key: "k"),
        ArtPixel(column: 24, row: 4, key: "W"),
        ArtPixel(column: 25, row: 4, key: "k"),
        ArtPixel(column: 28, row: 8, key: "p"),
        ArtPixel(column: 29, row: 8, key: "p"),
        ArtPixel(column: 29, row: 9, key: "p"),
    ]

    /// The eye turned down the muzzle, at something on the nose.
    static let eyeOnTheNose = [
        ArtPixel(column: 24, row: 4, key: "W"),
        ArtPixel(column: 25, row: 4, key: "W"),
        ArtPixel(column: 24, row: 5, key: "W"),
        ArtPixel(column: 25, row: 5, key: "k"),
        ArtPixel(column: 26, row: 5, key: "k"),
    ]

    /// The eye turned up, at something coming down.
    static let eyeUp = [
        ArtPixel(column: 24, row: 3, key: "k"),
        ArtPixel(column: 25, row: 3, key: "k"),
        ArtPixel(column: 24, row: 5, key: "W"),
        ArtPixel(column: 25, row: 5, key: "W"),
    ]

    /// The jaw dropped open: a moo.
    static let openMouth =
        (24...30).map { ArtPixel(column: $0, row: 10, key: "M") }
        + (24...29).map { ArtPixel(column: $0, row: 11, key: "M") }
        + (24...28).map { ArtPixel(column: $0, row: 12, key: "P") }

    /// Wider than a moo, up to the nostril.
    static let yawningMouth =
        (25...29).map { ArtPixel(column: $0, row: 9, key: "M") }
        + (24...29).map { ArtPixel(column: $0, row: 10, key: "M") }
        + (25...28).map { ArtPixel(column: $0, row: 11, key: "M") }

    /// The mouth open and the tongue hanging out.
    static let pantingMouth =
        (25...29).map { ArtPixel(column: $0, row: 10, key: "M") } + [
            ArtPixel(column: 26, row: 11, key: "P"),
            ArtPixel(column: 27, row: 11, key: "P"),
            ArtPixel(column: 26, row: 12, key: "P"),
            ArtPixel(column: 27, row: 12, key: "p"),
        ]

    /// The jaw slid back a pixel, then forward: chewing.
    static let chewingBack =
        (24...27).map { ArtPixel(column: $0, row: 10, key: "p") } + [
            ArtPixel(column: 28, row: 10, key: "P"),
            ArtPixel(column: 29, row: 10, key: "P"),
            ArtPixel(column: 30, row: 10, key: "."),
            ArtPixel(column: 23, row: 11, key: "P"),
        ]

    static let chewingForward =
        [ArtPixel(column: 25, row: 10, key: "P"), ArtPixel(column: 26, row: 10, key: "P")]
        + (27...30).map { ArtPixel(column: $0, row: 10, key: "p") } + [
            ArtPixel(column: 29, row: 11, key: "P"),
            ArtPixel(column: 30, row: 11, key: "P"),
            ArtPixel(column: 23, row: 11, key: "r"),
        ]

    /// The ear hanging down the side of the head: sorry about something.
    static let droopingEar = [
        ArtPixel(column: 14, row: 2, key: "."),
        ArtPixel(column: 15, row: 2, key: "."),
        ArtPixel(column: 16, row: 2, key: "."),
        ArtPixel(column: 13, row: 3, key: "."),
        ArtPixel(column: 14, row: 3, key: "."),
        ArtPixel(column: 15, row: 3, key: "."),
        ArtPixel(column: 14, row: 4, key: "."),
        ArtPixel(column: 14, row: 5, key: "K"),
        ArtPixel(column: 15, row: 5, key: "p"),
        ArtPixel(column: 16, row: 5, key: "K"),
        ArtPixel(column: 13, row: 6, key: "Y"),
        ArtPixel(column: 14, row: 6, key: "K"),
        ArtPixel(column: 15, row: 6, key: "K"),
        ArtPixel(column: 16, row: 6, key: "K"),
        ArtPixel(column: 17, row: 6, key: "K"),
    ]

    /// The bell swung out from under the chin, as the head swings the other
    /// way.
    static let bellSwungRight = [
        ArtPixel(column: 20, row: 13, key: "."),
        ArtPixel(column: 21, row: 13, key: "Y"),
        ArtPixel(column: 22, row: 13, key: "Y"),
        ArtPixel(column: 23, row: 13, key: "y"),
        ArtPixel(column: 21, row: 14, key: "."),
        ArtPixel(column: 23, row: 14, key: "y"),
    ]

    static let bellSwungLeft = [
        ArtPixel(column: 22, row: 13, key: "."),
        ArtPixel(column: 19, row: 13, key: "Y"),
        ArtPixel(column: 20, row: 13, key: "Y"),
        ArtPixel(column: 21, row: 13, key: "y"),
        ArtPixel(column: 21, row: 14, key: "."),
        ArtPixel(column: 19, row: 14, key: "y"),
    ]
}
