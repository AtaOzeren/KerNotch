import AppKit
import SwiftUI
import Testing

@testable import KerNotchCore
@testable import KerNotchUI

/// Todo 60's acceptance criterion is "every documented setting is reachable and
/// functional". Reachable is the tab list; functional is a control that moves
/// the bound value rather than a private copy of it — the same write-through
/// property `AIIntegrationsSettingsViewTests` asserts for the AI pane.
@Suite("Settings window")
@MainActor
struct SettingsWindowViewTests {
    private final class Box<Value>: @unchecked Sendable {
        var value: Value
        init(_ value: Value) { self.value = value }
        var binding: Binding<Value> {
            Binding(get: { self.value }, set: { self.value = $0 })
        }
    }

    @Test("every documented pane is a tab")
    func everyPaneIsATab() {
        #expect(SettingsTab.allCases == [.general, .activities, .pet, .aiIntegrations, .integrations, .about])
        for tab in SettingsTab.allCases {
            #expect(!tab.displayName.isEmpty)
            #expect(!tab.symbolName.isEmpty)
        }
    }

    @Test("picking a tab in the tab bar moves the window's selection")
    func tabBarMovesTheSelection() {
        let box = Box(SettingsTab.general)
        let tabBar = SettingsTabBar(selection: box.binding, tabs: SettingsTab.allCases)

        for tab in SettingsTab.allCases.reversed() {
            tabBar.select(tab)
            #expect(box.value == tab)
        }
    }

    @Test(
        "a pane is capped to what the window's screen can show",
        arguments: [
            (CGFloat?.none, CGFloat(680)),
            (1_400, 680),
            (620, 490),
            (300, 240),
        ]
    )
    func paneCeilingFollowsTheScreen(screenHeight: CGFloat?, ceiling: CGFloat) {
        #expect(SettingsPaneMetrics.default.paneCeiling(onScreenOfHeight: screenHeight) == ceiling)
    }

    /// The window sizes itself from the pane's scroll view, so that view has to
    /// claim the pane's own height — not whatever the window happens to offer —
    /// up to the ceiling, past which the pane scrolls.
    @Test(
        "the pane's scroll view takes the pane's height up to the ceiling",
        arguments: [(CGFloat(120), CGFloat(120)), (900, 300)]
    )
    func paneFittingFollowsTheContent(contentHeight: CGFloat, fittedHeight: CGFloat) {
        let host = NSHostingView(
            rootView: SettingsPaneFitting(maximumHeight: 300) {
                ScrollView {
                    Color.clear.frame(width: 200, height: contentHeight)
                }
            }
            .frame(width: 200)
        )

        #expect(host.fittingSize.height == fittedHeight)
    }

    @Test("every pane's row labels end in the form's colon")
    func formLabelsCarryTheColon() {
        #expect(settingsFormLabel("Display") == "Display:")
        #expect(settingsFormLabel("Island size") == "Island size:")
    }

    @Test("the About pane shows the build as version and build number")
    func aboutPaneDescribesTheBuild() {
        let view = AboutSettingsView(
            information: AboutInformation(version: "1.4.0", build: "42", musicBackendName: "test"),
            languageOverride: Box(String?.none).binding
        )

        #expect(view.versionDescription == "1.4.0 (42)")
    }

    @Test("the display picker offers all displays only when multiple screens are attached")
    func displayPickerEnumeratesAttachedDisplays() {
        let box = Box(GeneralPreferences.default)
        let view = GeneralSettingsView(
            preferences: box.binding,
            availableDisplays: [
                DisplayDescription(name: "Built-in Retina Display", isBuiltIn: true),
                DisplayDescription(name: "Studio Display", isBuiltIn: false),
            ]
        )

        #expect(
            view.displayOptions == [
                .automatic,
                .allDisplays,
                .builtIn,
                .identified(id: "Built-in Retina Display", name: "Built-in Retina Display"),
                .identified(id: "Studio Display", name: "Studio Display"),
            ])
        #expect(view.title(for: .named("Studio Display")) == "Studio Display")
        #expect(view.title(for: .allDisplays) == "All displays")
    }

    @Test("the display picker hides all displays when only one screen is attached")
    func displayPickerHidesAllDisplaysForOneScreen() {
        let box = Box(GeneralPreferences.default)
        let view = GeneralSettingsView(
            preferences: box.binding,
            availableDisplays: [
                DisplayDescription(name: "Built-in Retina Display", isBuiltIn: true),
            ]
        )

        #expect(!view.displayOptions.contains(.allDisplays))
    }

    @Test("the menu bar placement hint appears only for an enabled icon with multiple displays")
    func menuBarPlacementHintUsesLiveDisplayState() {
        let box = Box(GeneralPreferences.default)
        let multipleDisplays = [
            DisplayDescription(name: "Built-in Retina Display", isBuiltIn: true),
            DisplayDescription(name: "Studio Display", isBuiltIn: false),
        ]
        let view = GeneralSettingsView(
            preferences: box.binding,
            availableDisplays: multipleDisplays
        )

        #expect(view.shouldShowMenuBarPlacementHint)

        view.menuBarIconVisibility.wrappedValue = false
        #expect(!view.shouldShowMenuBarPlacementHint)
    }

    @Test("every General control writes through to the preferences")
    func generalControlsWriteThrough() {
        let box = Box(GeneralPreferences.default)
        let view = GeneralSettingsView(preferences: box.binding, availableDisplays: [])

        view.displayTarget.wrappedValue = .named("Studio Display")
        view.launchAtLogin.wrappedValue = true
        view.menuBarIconVisibility.wrappedValue = false
        view.appearance.wrappedValue = .dark
        view.islandSize.wrappedValue = .large
        view.hidesInFullScreen.wrappedValue = true

        #expect(box.value.displayTarget == .named("Studio Display"))
        #expect(box.value.launchAtLogin)
        #expect(box.value.showMenuBarIcon == false)
        #expect(box.value.appearance == .dark)
        #expect(box.value.islandSize == .large)
        #expect(box.value.hidesInFullScreen)
    }

    @Test("the full-screen switch starts off, keeping the island over full-screen apps")
    func fullScreenHidingStartsOff() {
        let box = Box(GeneralPreferences.default)
        let view = GeneralSettingsView(preferences: box.binding, availableDisplays: [])

        #expect(view.hidesInFullScreen.wrappedValue == false)
    }

    @Test("the island size picker starts on the minimalist island")
    func islandSizeDefaultsToMinimalist() {
        let box = Box(GeneralPreferences.default)
        let view = GeneralSettingsView(preferences: box.binding, availableDisplays: [])

        #expect(view.islandSize.wrappedValue == .minimalist)
        #expect(IslandSize.allCases == [.minimalist, .large])
    }

    @Test("the General restart control delegates one restart request")
    func generalRestartControlDelegates() {
        let box = Box(GeneralPreferences.default)
        var requestCount = 0
        let view = GeneralSettingsView(
            preferences: box.binding,
            availableDisplays: [],
            restartRequired: true,
            onRestart: { requestCount += 1 }
        )

        #expect(view.restartRequired)
        view.requestRestart()

        #expect(requestCount == 1)
    }

    /// The picker draws a selection only when the stored choice equals one of
    /// its rows, so a choice whose display number moved must come back as that
    /// display's row — not as a blank picker.
    @Test("a renumbered display's choice is one of the picker's rows")
    func renumberedChoiceMatchesAPickerRow() {
        let displays = [
            DisplayDescription(identifier: "3", name: "EPIC Q40", isBuiltIn: false),
            DisplayDescription(identifier: "2", name: "R27qe", isBuiltIn: false),
        ]
        let view = GeneralSettingsView(preferences: Box(GeneralPreferences.default).binding, availableDisplays: displays)
        let stored = DisplayPreference.identified(id: "2", name: "EPIC Q40")

        #expect(!view.displayOptions.contains(stored))
        #expect(view.displayOptions.contains(normalizeDisplayPreference(stored, availableDisplays: displays)))
    }

    @Test("duplicate display names receive distinct picker labels")
    func duplicateDisplayNamesAreDisambiguated() {
        let box = Box(GeneralPreferences.default)
        let view = GeneralSettingsView(
            preferences: box.binding,
            availableDisplays: [
                DisplayDescription(identifier: "101", name: "Studio Display", isBuiltIn: false),
                DisplayDescription(identifier: "202", name: "Studio Display", isBuiltIn: false),
            ]
        )

        #expect(view.displayOptions.map(view.title(for:)) == [
            "Automatic",
            "All displays",
            "Built-in display",
            "Studio Display (1)",
            "Studio Display (2)",
        ])
    }

    /// The three-way motion control maps onto a `Bool?`, so the round trip is
    /// worth asserting in both directions: a picker that cannot get back to
    /// "follow system" would strand the user on an override.
    @Test("the motion control round-trips through the optional override")
    func motionControlRoundTrips() {
        let box = Box(GeneralPreferences.default)
        let view = GeneralSettingsView(preferences: box.binding, availableDisplays: [])

        #expect(view.reducedMotion.wrappedValue == .followSystem)

        view.reducedMotion.wrappedValue = .alwaysReduce
        #expect(box.value.reducedMotionOverride == true)

        view.reducedMotion.wrappedValue = .neverReduce
        #expect(box.value.reducedMotionOverride == false)

        view.reducedMotion.wrappedValue = .followSystem
        #expect(box.value.reducedMotionOverride == nil)
    }

    @Test("every provider has a switch that writes through")
    func activityTogglesWriteThrough() {
        let box = Box(Set(ActivityProviderIdentifier.allCases))
        let view = ActivitiesSettingsView(enabledIdentifiers: box.binding)

        for identifier in ActivityProviderIdentifier.allCases {
            #expect(view.binding(for: identifier).wrappedValue)
            view.binding(for: identifier).wrappedValue = false
            #expect(!box.value.contains(identifier))
        }
        #expect(box.value.isEmpty)

        view.binding(for: .music).wrappedValue = true
        #expect(box.value == [.music])
    }

    @Test("the two recording sources are separately switchable")
    func recordingSourcesAreSeparateSwitches() {
        let box = Box(Set(ActivityProviderIdentifier.allCases))
        let view = ActivitiesSettingsView(enabledIdentifiers: box.binding)

        view.binding(for: .screenRecording).wrappedValue = false

        #expect(!box.value.contains(.screenRecording))
        #expect(box.value.contains(.audioRecording))
    }

    @Test("the language picker always offers a way back to the system default")
    func languagePickerOffersSystemDefault() {
        let box = Box(String?.none)
        let view = AboutSettingsView(
            information: AboutInformation(version: "1.0", build: "1", musicBackendName: "test"),
            languageOverride: box.binding,
            languages: [LanguageOption(code: "tr", displayName: "Türkçe")]
        )

        #expect(view.languageOptions.first == .systemDefault)
        #expect(view.selectedLanguage.wrappedValue == .systemDefault)

        view.selectedLanguage.wrappedValue = LanguageOption(code: "tr", displayName: "Türkçe")
        #expect(box.value == "tr")

        view.selectedLanguage.wrappedValue = .systemDefault
        #expect(box.value == nil)
    }

    /// An override the picker no longer lists — a language dropped between
    /// builds — must not leave the picker with no selection at all.
    @Test("an unlisted language override falls back to the system default")
    func unlistedOverrideFallsBack() {
        let box = Box(String?.some("xx"))
        let view = AboutSettingsView(
            information: AboutInformation(version: "1.0", build: "1", musicBackendName: "test"),
            languageOverride: box.binding
        )

        #expect(view.selectedLanguage.wrappedValue == .systemDefault)
    }

    @Test("the language pane exposes a pending restart")
    func languagePaneExposesPendingRestart() {
        let box = Box(String?.some("tr"))
        let view = AboutSettingsView(
            information: AboutInformation(version: "1.0", build: "1", musicBackendName: "test"),
            languageOverride: box.binding,
            restartRequired: true
        )

        #expect(view.restartRequired)
    }
}
