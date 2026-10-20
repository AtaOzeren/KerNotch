import KerNotchCore
import ServiceManagement
import SwiftUI

/// The General pane: display target, island size, hiding in full screen, menu
/// bar visibility, reduced motion, launch at login, and restarting the app.
///
/// Like the AI Integrations pane, it owns no state — it edits the binding the
/// composition root hands it, so the window and the store never hold two
/// generations of the same edit.
public struct GeneralSettingsView: View {
    @Binding private var preferences: GeneralPreferences
    private let availableDisplays: [DisplayDescription]
    private let metrics: SettingsPaneMetrics
    private let onRestart: () -> Void
    private let launchAtLoginNeedsApproval: Bool
    public let restartRequired: Bool

    public init(
        preferences: Binding<GeneralPreferences>,
        availableDisplays: [DisplayDescription],
        metrics: SettingsPaneMetrics = .default,
        launchAtLoginNeedsApproval: Bool = false,
        restartRequired: Bool = false,
        onRestart: @escaping () -> Void = {}
    ) {
        self._preferences = preferences
        self.availableDisplays = availableDisplays
        self.metrics = metrics
        self.launchAtLoginNeedsApproval = launchAtLoginNeedsApproval
        self.restartRequired = restartRequired
        self.onRestart = onRestart
    }

    /// The picker's rows: the two rules, then one row per attached display.
    ///
    /// Built from the displays passed in rather than read from `NSScreen` here,
    /// so a test can enumerate the picker without a second monitor plugged in.
    public var displayOptions: [DisplayPreference] {
        let attached = zip(availableDisplays, displayLabels(for: availableDisplays)).map { display, label in
            DisplayPreference.identified(id: display.identifier, name: label)
        }
        let allDisplays: [DisplayPreference] = availableDisplays.count > 1 ? [.allDisplays] : []
        return [.automatic] + allDisplays + [.builtIn] + attached
    }

    public func title(for preference: DisplayPreference) -> String {
        switch preference {
        case .automatic: localized("Automatic")
        case .allDisplays: localized("All displays")
        case .builtIn: localized("Built-in display")
        case .named(let name): name
        case .identified(_, let name): name
        }
    }

    public var displayTarget: Binding<DisplayPreference> {
        Binding(
            get: { preferences.displayTarget },
            set: { preferences.displayTarget = $0 }
        )
    }

    public var launchAtLogin: Binding<Bool> {
        Binding(
            get: { preferences.launchAtLogin },
            set: { preferences.launchAtLogin = $0 }
        )
    }

    public var appearance: Binding<SettingsAppearance> {
        Binding(
            get: { preferences.appearance },
            set: { preferences.appearance = $0 }
        )
    }

    public var islandSize: Binding<IslandSize> {
        Binding(
            get: { preferences.islandSize },
            set: { preferences.islandSize = $0 }
        )
    }

    public var hidesInFullScreen: Binding<Bool> {
        Binding(
            get: { preferences.hidesInFullScreen },
            set: { preferences.hidesInFullScreen = $0 }
        )
    }

    public var menuBarIconVisibility: Binding<Bool> {
        Binding(
            get: { preferences.showMenuBarIcon },
            set: { preferences.showMenuBarIcon = $0 }
        )
    }

    public var shouldShowMenuBarPlacementHint: Bool {
        preferences.showMenuBarIcon && availableDisplays.count > 1
    }

    func requestRestart() {
        onRestart()
    }

    public var reducedMotion: Binding<ReducedMotionSetting> {
        Binding(
            get: { ReducedMotionSetting(override: preferences.reducedMotionOverride) },
            set: { preferences.reducedMotionOverride = $0.override }
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
            displayRow
            SettingsFormDivider()
            islandSizeRow
            fullScreenRow
            SettingsFormDivider()
            menuBarRow
            motionRow
            SettingsFormDivider()
            startupRow
            applicationRow
        }
        .settingsPaneFrame(metrics)
    }

    private var displayRow: some View {
        SettingsFormRow(
            localized("Display"),
            caption: localized("Automatic follows the display with the notch, then falls back to the built-in screen."),
            metrics: metrics
        ) {
            Picker(localized("Show the island on"), selection: displayTarget) {
                ForEach(displayOptions, id: \.self) { option in
                    Text(title(for: option)).tag(option)
                }
            }
            .labelsHidden()
            .fixedSize()
        }
    }

    private var islandSizeRow: some View {
        SettingsFormRow(
            localized("Island size"),
            caption: localized("Large widens the island that opens on hover and enlarges its text and controls."),
            metrics: metrics
        ) {
            Picker(localized("Island size"), selection: islandSize) {
                ForEach(IslandSize.allCases, id: \.self) { size in
                    Text(size.displayName).tag(size)
                }
            }
            .settingsSegmentedPicker()
        }
    }

    private var fullScreenRow: some View {
        SettingsFormRow(localized("Full screen"), metrics: metrics) {
            Toggle(localized("Hide in full screen and Mission Control"), isOn: hidesInFullScreen)
        }
    }

    private var menuBarRow: some View {
        SettingsFormRow(localized("Menu bar"), metrics: metrics) {
            Toggle(localized("Show menu bar icon"), isOn: menuBarIconVisibility)
            if shouldShowMenuBarPlacementHint {
                SettingsCaption(
                    localized(
                        "macOS shows this icon on the main menu bar. With multiple displays, it may appear on another screen."
                    ),
                    metrics: metrics
                )
            }
        }
    }

    private var motionRow: some View {
        SettingsFormRow(
            localized("Motion"),
            caption: localized("Reduced motion also follows the system accessibility setting unless you override it."),
            metrics: metrics
        ) {
            Picker(localized("Motion"), selection: reducedMotion) {
                ForEach(ReducedMotionSetting.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .labelsHidden()
            .fixedSize()
        }
    }

    private var startupRow: some View {
        SettingsFormRow(
            localized("Startup"),
            caption: localized(
                "KerNotch has no Dock icon. Open the app again to show Settings when its menu bar icon is hidden."),
            metrics: metrics
        ) {
            Toggle(localized("Launch at login"), isOn: launchAtLogin)
            if launchAtLoginNeedsApproval {
                VStack(alignment: .leading, spacing: metrics.rowSpacing / 2) {
                    SettingsCaption(
                        localized("Allow KerNotch in Login Items to finish enabling launch at login."),
                        metrics: metrics
                    )
                    Button(localized("Open Login Items Settings")) {
                        SMAppService.openSystemSettingsLoginItems()
                    }
                    .buttonStyle(.link)
                }
                .accessibilityIdentifier("settings.general.launchAtLoginApproval")
            }
        }
    }

    private var applicationRow: some View {
        SettingsFormRow(
            localized("Application"),
            caption: restartRequired
                ? localized("Some changes need a restart. Finish your selections, then restart KerNotch.")
                : localized("Restarts KerNotch without changing your settings."),
            metrics: metrics
        ) {
            if restartRequired {
                SettingsRestartNotice()
            }
            Button(action: requestRestart) {
                Label(localized("Restart KerNotch"), systemImage: "arrow.clockwise")
            }
        }
    }
}
