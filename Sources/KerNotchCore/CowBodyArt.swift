/// The body under the cow's head, standing and lying with its legs folded,
/// and the legs: the blocks `CowArt` puts its frames together from, with the
/// tail, the props and what it carries below.
extension CowArt {
    /// Rump to chest, the tail hanging behind with its tuft. Rows 6 to 16 of a
    /// standing frame.
    static let standingBody = [
        ".....HKKKKWWWWWWWW..............",
        "...HKKKKKKKWWWWWWWW.............",
        "..HKKKKKKKWWWWWKKKWW............",
        "..KHKKKKKWWWWWKKKKKW............",
        "..K.WKKKWWWWWWKKKKKW............",
        "..K.WWWWWWWWWWWKKKWW............",
        "..K.WWWWWWWWWWWWWWWWW...........",
        "..K.wWWWWWWWWWWWWWWWW...........",
        ".HKH.wWWWWWWWWWWWWWWw...........",
        ".KKH.wwwWWWWWWWWWWWw............",
        "....wwwwwwPPwwwwwww.............",
    ]

    /// Standing square, the udder between the pairs. Each pair is the far
    /// leg, in shadow, and the near leg a pixel in front of it.
    static let standingLegs = [
        "....ww.WW.PP..ww.WW.............",
        "....ww.WW.....ww.WW.............",
        "....ww.WW.....ww.WW.............",
        "....ww.WW.....ww.WW.............",
        "....ww.WW.....ww.WW.............",
        "....hh.hh.....hh.hh.............",
        "....hh.hh.....hh.hh.............",
    ]

    /// Mid-stride, each pair spread from the knee down.
    static let strideALegs = [
        "....ww.WW.PP..ww.WW.............",
        "....ww.WW.....ww.WW.............",
        "...ww...WW...ww...WW............",
        "...ww...WW...ww...WW............",
        "...ww...WW...ww...WW............",
        "...hh...hh...hh...hh............",
        "...hh...hh...hh...hh............",
    ]

    /// The other half of the stride, each pair passing.
    static let strideBLegs = [
        "....ww.WW.PP..ww.WW.............",
        "....ww.WW.....ww.WW.............",
        ".....wWW.......wWW..............",
        ".....wWW.......wWW..............",
        ".....wWW.......wWW..............",
        ".....hhh.......hhh..............",
        ".....hhh.......hhh..............",
    ]

    /// In the air, the hind legs trailing and the front ones reaching.
    static let hopLegs = [
        "....ww.WW.PP..ww.WW.............",
        "...ww..WW......wwWW.............",
        "..ww....WW......wwWW............",
        "..hh.....hh......hhhh...........",
    ]

    /// The near front hoof raised, to stamp it down.
    static let stompingLegs = [
        "....ww.WW.PP..ww.WWW............",
        "....ww.WW.....ww..WWh...........",
        "....ww.WW.....ww...hh...........",
        "....ww.WW.....ww................",
        "....ww.WW.....ww................",
        "....hh.hh.....hh................",
        "....hh.hh.....hh................",
    ]

    /// Lying with the legs folded under, the belly on the floor and a front
    /// hoof showing beneath the chest. Rows 13 to 23.
    static let tuckedBody = [
        ".....HKKKKWWWWWWWW..............",
        "...HKKKKKKKWWWWWWWW.............",
        "..HKKKKKKKWWWWWKKKWW............",
        "..KHKKKKKWWWWWKKKKKW............",
        "..K.WKKKWWWWWWKKKKKW............",
        "..K.WWWWWWWWWWWKKKWW............",
        "..K.WWWWWWWWWWWWWWWWW...........",
        ".HKHWWWWWWWWWWWWWWWWW...........",
        ".KKHwWWWWWWWWWWWWWWWw...........",
        "...wwWWWwwwWWWWWWwwWWWh.........",
        "...wwwwwwwwwwwwwwwwwwhh.........",
    ]

    /// The same with the tail flicked up off the floor.
    static let tuckedBodyWagging =
        [
            "..HK.HKKKKWWWWWWWW..............",
            ".HK.HKKKKKKKWWWWWWWW............",
            ".K.HKKKKKKKWWWWWKKKWW...........",
            "...KHKKKKKWWWWWKKKKKW...........",
        ] + tuckedBody.dropFirst(4)

    /// Kneeling: the front legs folded, knees on the floor.
    static let foldedFrontLegs = [
        "............wwWWWW..",
        "...........hwwWWWWh.",
        "...........hhwwwww..",
    ]

    /// Stretched out along the floor in front, for the stretch on waking.
    static let stretchedFrontLegs = [
        "...........wwwwwwwwwhh",
        "...........WWWWWWWWWhh",
    ]

    /// Kicked straight out behind, hooves first.
    static let kickingHindLegs = [
        "hhwwWW",
        "hhwwWW",
    ]
}

/// The tail swishing: where it hangs in a standing frame, and the two places
/// it is flicked to.
extension CowArt {
    static let tailErased =
        (9...13).map { ArtPixel(column: 2, row: $0, key: ".") }
        + [1, 2, 3].flatMap { column in [14, 15].map { ArtPixel(column: column, row: $0, key: ".") } }

    /// Up and out behind.
    static let tailUp = [
        ArtPixel(column: 2, row: 9, key: "K"),
        ArtPixel(column: 1, row: 8, key: "K"),
        ArtPixel(column: 1, row: 7, key: "K"),
        ArtPixel(column: 0, row: 6, key: "K"),
        ArtPixel(column: 0, row: 5, key: "H"),
        ArtPixel(column: 1, row: 5, key: "K"),
        ArtPixel(column: 0, row: 4, key: "K"),
        ArtPixel(column: 1, row: 4, key: "H"),
    ]

    /// Swung down and back.
    static let tailFlicked = [
        ArtPixel(column: 2, row: 9, key: "K"),
        ArtPixel(column: 1, row: 10, key: "K"),
        ArtPixel(column: 1, row: 11, key: "K"),
        ArtPixel(column: 0, row: 12, key: "K"),
        ArtPixel(column: 0, row: 13, key: "H"),
        ArtPixel(column: 1, row: 13, key: "K"),
        ArtPixel(column: 0, row: 14, key: "K"),
        ArtPixel(column: 1, row: 14, key: "H"),
    ]
}

/// What the cow wears, works with and eats.
extension CowArt {
    /// Over the horns, a cup over the ear and the microphone down to the
    /// muzzle.
    static let headset = [
        "..................gGGGGGGg......",
        ".................G........G.....",
        "................gGg.............",
        "................GGg.............",
        "................gGg.............",
        ".................g..............",
        "..................ggggg.........",
    ]

    /// On the floor before the muzzle: the screen with a prompt and the cursor
    /// lit, over the keys.
    static let laptop = [
        "...gggggg",
        "...gSLSSg",
        "...gSSLSg",
        "...gSLSLg",
        "GGGGGGGGG",
    ]

    /// The same with the cursor out.
    static let laptopCursorOff = [
        "...gggggg",
        "...gSLSSg",
        "...gSSLSg",
        "...gSLSSg",
        "GGGGGGGGG",
    ]

    /// A front hoof reached out onto the keys, and lifted between keystrokes.
    static let hoofOnTheKeys = [
        ArtPixel(column: 22, row: 22, key: "W"),
        ArtPixel(column: 23, row: 22, key: "W"),
        ArtPixel(column: 24, row: 22, key: "h"),
    ]

    static let hoofLifted = [
        ArtPixel(column: 22, row: 21, key: "W"),
        ArtPixel(column: 23, row: 21, key: "W"),
        ArtPixel(column: 24, row: 21, key: "h"),
    ]

    /// A pail beside it, filling with milk from the bottom as an agent works.
    /// Drawn as an outline, so the milk shows against the island's black.
    static let lowPail = [
        "G......G",
        ".g....g.",
        ".g....g.",
        ".gWWWWg.",
        "..gggg..",
    ]

    static let halfPail = [
        "G......G",
        ".g....g.",
        ".gWWWWg.",
        ".gWWWWg.",
        "..gggg..",
    ]

    static let fullPail = [
        "GWWWWWWG",
        ".gWWWWg.",
        ".gWWWWg.",
        ".gWWWWg.",
        "..gggg..",
    ]

    /// A daisy held in the mouth.
    static let heldDaisy = [
        "..W..",
        ".WYW.",
        "..W..",
    ]
}
