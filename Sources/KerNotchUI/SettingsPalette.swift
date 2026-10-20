import AppKit
import SwiftUI

/// An sRGB colour as the hex triplet a design file names it by.
struct SettingsRGB: Equatable, Sendable {
    let hex: UInt32
    let alpha: Double

    init(_ hex: UInt32, alpha: Double = 1) {
        self.hex = hex
        self.alpha = alpha
    }

    var red: Double { Double((hex >> 16) & 0xFF) / 255 }
    var green: Double { Double((hex >> 8) & 0xFF) / 255 }
    var blue: Double { Double(hex & 0xFF) / 255 }

    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }

    /// WCAG 2 relative luminance, the input to `contrastRatio(against:)`.
    var relativeLuminance: Double {
        func linearized(_ channel: Double) -> Double {
            channel <= 0.039_28 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
    }

    /// WCAG 2 contrast ratio between two opaque colours, from 1 to 21.
    func contrastRatio(against other: SettingsRGB) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// One colour of the settings window, as the value it takes in the light
/// appearance and the value it takes in the dark one.
///
/// The window follows the system appearance by itself — KerNotch offers no
/// setting for it — so no view picks a colour by reading `colorScheme`. Each
/// tone is a dynamic `NSColor` instead, which AppKit resolves against the
/// window's appearance every time it draws: switching macOS between light and
/// dark repaints the window without a single view body being evaluated again.
struct SettingsTone: Equatable, Sendable {
    let light: SettingsRGB
    let dark: SettingsRGB
    /// Built once rather than on every read, so SwiftUI sees the same colour
    /// on each evaluation instead of a new one that never compares equal.
    let nsColor: NSColor
    let color: Color

    init(light: SettingsRGB, dark: SettingsRGB) {
        self.light = light
        self.dark = dark
        let nsColor = NSColor(name: nil) { appearance in
            (appearance.isDarkSettingsAppearance ? dark : light).nsColor
        }
        self.nsColor = nsColor
        self.color = Color(nsColor: nsColor)
    }

    init(light: UInt32, dark: UInt32) {
        self.init(light: SettingsRGB(light), dark: SettingsRGB(dark))
    }

    static func == (lhs: SettingsTone, rhs: SettingsTone) -> Bool {
        lhs.light == rhs.light && lhs.dark == rhs.dark
    }

    func resolved(in appearance: NSAppearance) -> SettingsRGB {
        appearance.isDarkSettingsAppearance ? dark : light
    }
}

extension NSAppearance {
    /// Whether the settings window draws its dark tones under this appearance.
    ///
    /// Matched against the two base appearances so the high-contrast variants
    /// land on their own base rather than on a hard-coded name list.
    var isDarkSettingsAppearance: Bool {
        bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
}

/// The settings window's colours: design B's palette, each in both appearances.
///
/// Native controls — pop-up buttons, segmented pickers, checkboxes — keep the
/// system's own colours, which already follow the appearance and the Increase
/// Contrast setting. The palette covers only what the window draws itself.
enum SettingsPalette {
    static let windowBackground = SettingsTone(light: 0xF6F6F7, dark: 0x232325)
    static let tabBarBackground = SettingsTone(light: 0xECECEE, dark: 0x2A2A2C)
    static let tabBarSeparator = SettingsTone(
        light: SettingsRGB(0x000000, alpha: 0.10),
        dark: SettingsRGB(0xFFFFFF, alpha: 0.07)
    )
    /// An unselected tab's symbol and title.
    static let tabTitle = SettingsTone(light: 0x48484D, dark: 0xC7C7CC)
    /// The hairline around the selected tab, which keeps its black from
    /// dissolving into the dark tab bar. The light bar needs none.
    static let selectedTabRim = SettingsTone(
        light: SettingsRGB(0xFFFFFF, alpha: 0),
        dark: SettingsRGB(0xFFFFFF, alpha: 0.16)
    )
    /// Lifts the selected tab off the light bar; a shadow is invisible on the
    /// dark one.
    static let selectedTabShadow = SettingsTone(
        light: SettingsRGB(0x000000, alpha: 0.18),
        dark: SettingsRGB(0x000000, alpha: 0)
    )
    /// The trailing-aligned label in front of each row.
    static let rowLabel = SettingsTone(light: 0x3A3A3C, dark: 0xD1D1D6)
    /// The explanation under a row's controls.
    static let caption = SettingsTone(light: 0x6E6E73, dark: 0x98989D)
    /// The hairline between groups of rows.
    static let separator = SettingsTone(
        light: SettingsRGB(0x000000, alpha: 0.08),
        dark: SettingsRGB(0xFFFFFF, alpha: 0.07)
    )
    /// Text saying something is set up and working. Darker than the system
    /// green on the light background, where that green fails text contrast.
    static let positive = SettingsTone(light: 0x1E7A35, dark: 0x30D158)
    /// Text asking for the user's attention, such as a pending restart.
    static let warning = SettingsTone(light: 0xB25000, dark: 0xFF9F0A)

    /// The notch's own black, behind the selected tab in both appearances: the
    /// island standing in for a selection highlight.
    static let selectedTabBackground = Color.black
    /// The app icon's live green, on the selected tab's black.
    static let selectedTabSymbol = Color(nsColor: SettingsRGB(0x30D158).nsColor)
    /// The checkboxes' tint. The system green, which macOS itself resolves for
    /// the appearance and the contrast setting in force.
    static let accent = Color(nsColor: .systemGreen)
}
