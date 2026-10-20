import Testing

@testable import KerNotchCore

@Suite("DisplaySelection")
struct DisplaySelectionTests {
    private let builtIn = DisplayDescription(name: "Built-in Retina Display", isBuiltIn: true)
    private let studioDisplay = DisplayDescription(name: "Studio Display", isBuiltIn: false)

    @Test("selects the built-in display in automatic mode when it is the only screen")
    func automaticWithBuiltInOnly() {
        #expect(selectDisplay(from: [builtIn], preference: .automatic) == builtIn)
    }

    @Test("selects the built-in display automatically or when explicitly chosen")
    func builtInWithExternal() {
        #expect(selectDisplay(from: [studioDisplay, builtIn], preference: .automatic) == builtIn)
        #expect(selectDisplay(from: [studioDisplay, builtIn], preference: .builtIn) == builtIn)
        #expect(
            selectDisplay(from: [studioDisplay, builtIn], preference: .named(builtIn.name)) == builtIn
        )
    }

    @Test("selects a connected named external display")
    func connectedNamedExternal() {
        #expect(
            selectDisplay(from: [builtIn, studioDisplay], preference: .named(studioDisplay.name))
                == studioDisplay
        )
    }

    @Test("falls back to the built-in display when the named external disconnects")
    func disconnectedNamedExternal() {
        #expect(
            selectDisplay(from: [builtIn], preference: .named(studioDisplay.name)) == builtIn
        )
    }

    @Test("selects the sole external display in automatic clamshell mode")
    func automaticClamshell() {
        #expect(selectDisplay(from: [studioDisplay], preference: .automatic) == studioDisplay)
    }

    @Test("falls back to the connected external display in named clamshell mode")
    func namedClamshellFallback() {
        #expect(
            selectDisplay(from: [studioDisplay], preference: .named("Disconnected Display"))
                == studioDisplay
        )
    }

    @Test("returns to the built-in display in automatic mode after the lid reopens")
    func automaticAfterLidReopens() {
        #expect(selectDisplay(from: [studioDisplay, builtIn], preference: .automatic) == builtIn)
    }

    @Test("selects no display while no screens are available")
    func noScreensAvailable() {
        #expect(selectDisplay(from: [], preference: .automatic) == nil)
        #expect(selectDisplay(from: [], preference: .named(studioDisplay.name)) == nil)
    }

    @Test("stable identity distinguishes two displays with the same model name")
    func duplicateNamesUseIdentity() {
        let left = DisplayDescription(identifier: "101", name: "Studio Display", isBuiltIn: false)
        let right = DisplayDescription(identifier: "202", name: "Studio Display", isBuiltIn: false)

        #expect(
            selectDisplay(
                from: [left, right],
                preference: .identified(id: right.identifier, name: right.name)
            ) == right
        )
    }

    @Test("falls back to the built-in display when the identified display detaches")
    func identifiedDisplayDetachedFallsBack() {
        let detached = DisplayDescription(identifier: "65537", name: "Studio Display", isBuiltIn: false)

        #expect(
            selectDisplay(
                from: [builtIn],
                preference: .identified(id: detached.identifier, name: detached.name)
            ) == builtIn
        )
    }

    @Test("all-displays mode selects every connected display")
    func allDisplaysSelectsEveryScreen() {
        #expect(
            selectDisplays(
                from: [studioDisplay, builtIn],
                preference: .allDisplays
            ) == [studioDisplay, builtIn]
        )
    }

    @Test("all-displays mode degrades to the sole connected display")
    func allDisplaysWithOneScreen() {
        #expect(selectDisplays(from: [builtIn], preference: .allDisplays) == [builtIn])
        #expect(selectDisplays(from: [], preference: .allDisplays).isEmpty)
        #expect(normalizeDisplayPreference(.allDisplays, availableDisplays: [builtIn]) == .automatic)
        #expect(normalizeDisplayPreference(.allDisplays, availableDisplays: []) == .automatic)
        #expect(normalizeDisplayPreference(.allDisplays, availableDisplays: [builtIn, studioDisplay]) == .allDisplays)
    }

    // MARK: - Display numbers that move

    /// macOS gives display numbers out again across reconnects and sleep: the
    /// monitor the user chose as "2" can come back as "3" while "2" goes to
    /// another monitor. The choice follows the monitor, not the number.
    private let epic = DisplayDescription(identifier: "3", name: "EPIC Q40", isBuiltIn: false)
    private let r27 = DisplayDescription(identifier: "2", name: "R27qe", isBuiltIn: false)

    @Test("follows a chosen display whose number moved to another monitor")
    func followsRenumberedDisplayByName() {
        #expect(selectDisplay(from: [epic, r27], preference: .identified(id: "2", name: "EPIC Q40")) == epic)
        #expect(selectDisplay(from: [r27, epic], preference: .identified(id: "2", name: "EPIC Q40")) == epic)
    }

    @Test("does not follow the old number onto another monitor while the chosen one is away")
    func renumberedDisplayAwayFallsBack() {
        #expect(
            selectDisplay(from: [r27, builtIn], preference: .identified(id: "2", name: "EPIC Q40")) == builtIn
        )
    }

    @Test("keeps the built-in display by number when its name follows another language")
    func builtInKeepsItsNumberAcrossLanguages() {
        let builtInTurkish = DisplayDescription(identifier: "1", name: "Yerleşik Retina Ekran", isBuiltIn: true)

        #expect(
            selectDisplay(
                from: [r27, builtInTurkish],
                preference: .identified(id: "1", name: "Built-in Retina Display")
            ) == builtInTurkish
        )
    }

    @Test("keeps a display by number while its name has not resolved yet")
    func unresolvedNameKeepsTheNumber() {
        let resolving = DisplayDescription(identifier: "3", name: "", isBuiltIn: false)

        #expect(
            selectDisplay(from: [r27, resolving], preference: .identified(id: "3", name: "EPIC Q40")) == resolving
        )
    }

    @Test("finds a numbered twin by its picker name once its number moved")
    func renumberedTwinFoundByLabel() {
        let left = DisplayDescription(identifier: "101", name: "Studio Display", isBuiltIn: false)
        let right = DisplayDescription(identifier: "202", name: "Studio Display", isBuiltIn: false)

        #expect(
            selectDisplay(from: [left, right], preference: .identified(id: "999", name: "Studio Display (2)")) == right
        )
    }

    @Test("picker names number only the displays that share a name")
    func displayLabelsNumberSharedNames() {
        let left = DisplayDescription(identifier: "101", name: "Studio Display", isBuiltIn: false)
        let right = DisplayDescription(identifier: "202", name: "Studio Display", isBuiltIn: false)

        #expect(displayLabels(for: [builtIn, left, right]) == [
            "Built-in Retina Display", "Studio Display (1)", "Studio Display (2)",
        ])
        #expect(displayLabels(for: []).isEmpty)
    }

    // MARK: - Normalizing the stored choice

    @Test("re-points a renumbered choice at the display's current number")
    func normalizationRepointsRenumberedDisplay() {
        #expect(
            normalizeDisplayPreference(.identified(id: "2", name: "EPIC Q40"), availableDisplays: [epic, r27])
                == .identified(id: "3", name: "EPIC Q40")
        )
    }

    @Test("leaves a choice whose display is connected under its own number unchanged")
    func normalizationKeepsAnAccurateChoice() {
        let choice = DisplayPreference.identified(id: "3", name: "EPIC Q40")

        #expect(normalizeDisplayPreference(choice, availableDisplays: [epic, r27]) == choice)
    }

    @Test("keeps the stored choice while its display is away, for when it returns")
    func normalizationKeepsAnAbsentChoice() {
        let choice = DisplayPreference.identified(id: "2", name: "EPIC Q40")

        #expect(normalizeDisplayPreference(choice, availableDisplays: [r27, builtIn]) == choice)
        #expect(normalizeDisplayPreference(choice, availableDisplays: []) == choice)
    }

    @Test("never overwrites the stored name with one that has not resolved yet")
    func normalizationIgnoresAnUnresolvedName() {
        let choice = DisplayPreference.identified(id: "3", name: "EPIC Q40")
        let resolving = DisplayDescription(identifier: "3", name: "", isBuiltIn: false)

        #expect(normalizeDisplayPreference(choice, availableDisplays: [r27, resolving]) == choice)
    }

    @Test("renames the built-in choice into the language its display now uses")
    func normalizationFollowsTheBuiltInName() {
        let builtInTurkish = DisplayDescription(identifier: "1", name: "Yerleşik Retina Ekran", isBuiltIn: true)

        #expect(
            normalizeDisplayPreference(
                .identified(id: "1", name: "Built-in Retina Display"),
                availableDisplays: [builtInTurkish]
            ) == .identified(id: "1", name: "Yerleşik Retina Ekran")
        )
    }

    @Test("leaves rule-based choices alone")
    func normalizationLeavesRules() {
        for rule in [DisplayPreference.automatic, .builtIn, .named("EPIC Q40")] {
            #expect(normalizeDisplayPreference(rule, availableDisplays: [epic, r27]) == rule)
        }
    }

    @Test("single-display preferences still produce one target")
    func singleDisplayPreferenceProducesOneTarget() {
        #expect(selectDisplays(from: [studioDisplay, builtIn], preference: .automatic) == [builtIn])
        #expect(
            selectDisplays(
                from: [studioDisplay, builtIn],
                preference: .identified(id: studioDisplay.identifier, name: studioDisplay.name)
            ) == [studioDisplay]
        )
    }
}
