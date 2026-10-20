import AppKit
import SwiftUI
import Testing

@testable import KerNotchCore
@testable import KerNotchUI

/// The settings window follows the system's light or dark appearance by
/// itself — KerNotch has no setting for it — so these pin both halves of that
/// promise: every colour the window paints has a readable value in each
/// appearance, and nothing pins the window to one of them.
@Suite("Settings appearance", .serialized)
@MainActor
struct SettingsAppearanceTests {
    nonisolated private static let paintedTones: [(String, SettingsTone)] = [
        ("window background", SettingsPalette.windowBackground),
        ("tab bar background", SettingsPalette.tabBarBackground),
        ("tab bar separator", SettingsPalette.tabBarSeparator),
        ("tab title", SettingsPalette.tabTitle),
        ("selected tab rim", SettingsPalette.selectedTabRim),
        ("selected tab shadow", SettingsPalette.selectedTabShadow),
        ("row label", SettingsPalette.rowLabel),
        ("caption", SettingsPalette.caption),
        ("separator", SettingsPalette.separator),
        ("positive", SettingsPalette.positive),
        ("warning", SettingsPalette.warning),
    ]

    /// Each piece of text and the surface it is drawn on.
    nonisolated private static let textOnSurface: [(String, SettingsTone, SettingsTone)] = [
        ("row label", SettingsPalette.rowLabel, SettingsPalette.windowBackground),
        ("caption", SettingsPalette.caption, SettingsPalette.windowBackground),
        ("positive status", SettingsPalette.positive, SettingsPalette.windowBackground),
        ("warning", SettingsPalette.warning, SettingsPalette.windowBackground),
        ("tab title", SettingsPalette.tabTitle, SettingsPalette.tabBarBackground),
    ]

    @Test("every painted colour has its own light and dark value", arguments: paintedTones)
    func everyToneDiffersByAppearance(name: String, tone: SettingsTone) {
        #expect(tone.light != tone.dark, "\(name) paints the same in both appearances")
    }

    @Test(
        "a tone resolves to the value of the appearance it is drawn in",
        arguments: [
            (NSAppearance.Name.aqua, false),
            (.darkAqua, true),
            (.accessibilityHighContrastAqua, false),
            (.accessibilityHighContrastDarkAqua, true),
        ]
    )
    func toneFollowsTheDrawingAppearance(name: NSAppearance.Name, isDark: Bool) throws {
        let appearance = try #require(NSAppearance(named: name))
        let tone = SettingsPalette.windowBackground
        let expected = isDark ? tone.dark : tone.light

        #expect(tone.resolved(in: appearance) == expected)

        var drawn: NSColor?
        appearance.performAsCurrentDrawingAppearance {
            drawn = tone.nsColor.usingColorSpace(.sRGB)
        }
        let color = try #require(drawn)
        #expect(abs(color.redComponent - expected.red) < 0.005)
        #expect(abs(color.greenComponent - expected.green) < 0.005)
        #expect(abs(color.blueComponent - expected.blue) < 0.005)
    }

    @Test("text stays readable in both appearances", arguments: textOnSurface)
    func textMeetsContrast(name: String, text: SettingsTone, surface: SettingsTone) {
        #expect(text.light.contrastRatio(against: surface.light) >= 4.5, "\(name) is too faint in light")
        #expect(text.dark.contrastRatio(against: surface.dark) >= 4.5, "\(name) is too faint in dark")
    }

    @Test("contrast is measured the way WCAG defines it")
    func contrastRatioMatchesWCAG() {
        #expect(abs(SettingsRGB(0x000000).contrastRatio(against: SettingsRGB(0xFFFFFF)) - 21) < 0.001)
        #expect(SettingsRGB(0x777777).contrastRatio(against: SettingsRGB(0x777777)) == 1)
        #expect(abs(SettingsRGB(0x767676).contrastRatio(against: SettingsRGB(0xFFFFFF)) - 4.54) < 0.01)
    }

    @Test("the window chrome hides the title bar without pinning an appearance")
    func chromeLeavesTheAppearanceToTheSystem() {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )

        SettingsWindowChrome.apply(to: window)

        #expect(window.styleMask.contains(.fullSizeContentView))
        #expect(window.styleMask.contains(.titled), "the traffic lights must stay")
        #expect(window.titlebarAppearsTransparent)
        #expect(window.titleVisibility == .hidden)
        #expect(window.appearance == nil)
    }

    /// End to end: the same view, hosted in a light and then a dark window,
    /// paints the tab bar and the pane in that appearance's values.
    ///
    /// Each pixel is compared with a swatch of the expected colour rendered the
    /// same way, not with the hex itself: an off-screen bitmap is drawn in the
    /// display's colour space, so its pixels are the hex after colour
    /// management, and only a swatch goes through the same conversion.
    @Test(
        "the settings window paints itself in the appearance it is shown in",
        arguments: [(NSAppearance.Name.aqua, false), (.darkAqua, true)]
    )
    func windowPaintsInItsAppearance(name: NSAppearance.Name, isDark: Bool) throws {
        let appearance = try #require(NSAppearance(named: name))
        let snapshot = try Self.render(
            SettingsWindowView(
                general: .constant(GeneralPreferences()),
                enabledIdentifiers: .constant([]),
                aiPreferences: .constant(AIIntegrationPreferences()),
                languageOverride: .constant(nil),
                availableDisplays: [],
                information: AboutInformation(version: "1.0", build: "1", musicBackendName: "test")
            ),
            appearance: appearance
        )
        let tabBar = isDark ? SettingsPalette.tabBarBackground.dark : SettingsPalette.tabBarBackground.light
        let pane = isDark ? SettingsPalette.windowBackground.dark : SettingsPalette.windowBackground.light

        try Self.expect(snapshot.color(at: CGPoint(x: 4, y: 20)), matches: Self.swatch(tabBar, appearance: appearance))
        try Self.expect(
            snapshot.color(at: CGPoint(x: 4, y: snapshot.height - 4)),
            matches: Self.swatch(pane, appearance: appearance)
        )
    }

    private struct Snapshot {
        let bitmap: NSBitmapImageRep
        let height: CGFloat
        private let scale: CGFloat

        init(bitmap: NSBitmapImageRep, size: CGSize) {
            self.bitmap = bitmap
            self.height = size.height
            self.scale = CGFloat(bitmap.pixelsWide) / size.width
        }

        /// The colour at a point measured from the top-left corner.
        func color(at point: CGPoint) -> NSColor? {
            bitmap.colorAt(x: Int(point.x * scale), y: Int(point.y * scale))
        }
    }

    /// A fixed colour, drawn through the same pipeline as the window.
    private static func swatch(_ rgb: SettingsRGB, appearance: NSAppearance) throws -> NSColor? {
        let swatch = Rectangle()
            .fill(Color(nsColor: rgb.nsColor))
            .frame(width: 16, height: 16)
        return try render(swatch, appearance: appearance).color(at: CGPoint(x: 8, y: 8))
    }

    /// Hosted in a real window and given a run-loop turn first, the way the
    /// island's render tests are: before that, SwiftUI's layers are not attached.
    private static func render(_ view: some View, appearance: NSAppearance) throws -> Snapshot {
        let host = NSHostingView(rootView: view)
        let size = host.fittingSize
        let window = NSWindow(
            contentRect: CGRect(origin: CGPoint(x: -4000, y: -4000), size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = appearance
        window.contentView = host
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))

        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        return Snapshot(bitmap: bitmap, size: size)
    }

    private static func expect(_ drawn: NSColor?, matches expected: NSColor?) throws {
        let color = try #require(drawn?.usingColorSpace(.sRGB))
        let reference = try #require(expected?.usingColorSpace(.sRGB))
        let tolerance = 2.0 / 255
        #expect(abs(color.redComponent - reference.redComponent) <= tolerance, "\(color) ≠ \(reference)")
        #expect(abs(color.greenComponent - reference.greenComponent) <= tolerance)
        #expect(abs(color.blueComponent - reference.blueComponent) <= tolerance)
    }
}
