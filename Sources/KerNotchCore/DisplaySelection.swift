public struct DisplayDescription: Equatable, Sendable {
    public let identifier: String
    public let name: String
    public let isBuiltIn: Bool

    public init(identifier: String? = nil, name: String, isBuiltIn: Bool) {
        self.identifier = identifier ?? name
        self.name = name
        self.isBuiltIn = isBuiltIn
    }
}

public enum DisplayPreference: Equatable, Hashable, Sendable {
    case automatic
    case allDisplays
    case builtIn
    case named(String)
    case identified(id: String, name: String)
}

public func selectDisplay(
    from availableDisplays: [DisplayDescription],
    preference: DisplayPreference
) -> DisplayDescription? {
    guard
        let fallbackDisplay = availableDisplays.first(where: \.isBuiltIn)
            ?? availableDisplays.first
    else {
        return nil
    }

    switch preference {
    case .automatic, .allDisplays, .builtIn:
        return fallbackDisplay
    case .named(let name):
        return availableDisplays.first { $0.name == name } ?? fallbackDisplay
    case .identified(let id, let name):
        return identifiedDisplayIndex(id: id, name: name, in: availableDisplays).map { availableDisplays[$0] }
            ?? fallbackDisplay
    }
}

/// The name each display goes by in the Settings picker: its own name, or, when
/// two displays share one, that name numbered in screen order.
public func displayLabels(for displays: [DisplayDescription]) -> [String] {
    let nameCounts = Dictionary(grouping: displays, by: \.name).mapValues(\.count)
    var seenNames: [String: Int] = [:]
    return displays.map { display in
        seenNames[display.name, default: 0] += 1
        return nameCounts[display.name, default: 0] > 1
            ? "\(display.name) (\(seenNames[display.name, default: 1]))"
            : display.name
    }
}

/// Where in `displays` the display an `.identified` preference means is, or
/// `nil` while it is not connected.
///
/// macOS hands display numbers out again as monitors come and go, so a stored
/// number can end up on another monitor. The display is therefore followed by
/// its name, as `docs/03-display-and-notch.md` specifies, and by its number
/// only where the name is no guide: the built-in display, whose name follows
/// the system language, and a display whose name has not resolved yet.
func identifiedDisplayIndex(id: String, name: String, in displays: [DisplayDescription]) -> Int? {
    let labels = displayLabels(for: displays)
    let carriesName = { (index: Int) in displays[index].name == name || labels[index] == name }

    if let exact = displays.indices.first(where: { displays[$0].identifier == id && carriesName($0) }) {
        return exact
    }
    if let renumbered = displays.indices.first(where: { labels[$0] == name })
        ?? displays.indices.first(where: { displays[$0].name == name })
    {
        return renumbered
    }
    return displays.indices.first { index in
        displays[index].identifier == id && (displays[index].isBuiltIn || displays[index].name.isEmpty)
    }
}

public func selectDisplays(
    from availableDisplays: [DisplayDescription],
    preference: DisplayPreference
) -> [DisplayDescription] {
    guard preference != .allDisplays else { return availableDisplays }
    return selectDisplay(from: availableDisplays, preference: preference).map { [$0] } ?? []
}

/// The preference as the Settings picker should hold it for the displays
/// connected now.
///
/// "All displays" with fewer than two screens reads as automatic. An identified
/// display is re-pointed at its current number and picker name, so the picker
/// shows it selected and the corrected number is what gets saved; while that
/// display is away, or its name has not resolved yet, the stored choice is kept
/// for when it returns.
public func normalizeDisplayPreference(
    _ preference: DisplayPreference,
    availableDisplays: [DisplayDescription]
) -> DisplayPreference {
    switch preference {
    case .allDisplays where availableDisplays.count < 2:
        return .automatic
    case .identified(let id, let name):
        guard
            let index = identifiedDisplayIndex(id: id, name: name, in: availableDisplays),
            availableDisplays[index].name.isEmpty == false
        else {
            return preference
        }
        return .identified(
            id: availableDisplays[index].identifier,
            name: displayLabels(for: availableDisplays)[index]
        )
    default:
        return preference
    }
}
