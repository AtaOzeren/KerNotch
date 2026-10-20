import SwiftUI

/// The row of tabs across the top of the settings window.
///
/// Drawn rather than left to `TabView`, whose toolbar tabs cannot carry the
/// design's selected state: the notch's black behind the chosen tab and its
/// symbol in the app icon's live green — the island itself standing in for a
/// highlight, in the light appearance and the dark one alike.
struct SettingsTabBar: View {
    private static let topInset: CGFloat = 2
    private static let bottomInset: CGFloat = 8
    private static let tabSpacing: CGFloat = 4

    @Binding private var selection: SettingsTab
    private let tabs: [SettingsTab]

    init(selection: Binding<SettingsTab>, tabs: [SettingsTab]) {
        self._selection = selection
        self.tabs = tabs
    }

    /// Exposed so a test can drive the same path a click takes.
    func select(_ tab: SettingsTab) {
        selection = tab
    }

    var body: some View {
        HStack(spacing: Self.tabSpacing) {
            ForEach(tabs, id: \.self) { tab in
                SettingsTabButton(tab: tab, isSelected: tab == selection) {
                    select(tab)
                }
            }
        }
        .padding(.top, Self.topInset)
        .padding(.bottom, Self.bottomInset)
        .frame(maxWidth: .infinity)
        // The tabs stay below the title bar, which keeps the clicks it
        // receives; only the bar's colour reaches up behind the traffic
        // lights, so the two read as one band.
        .background(SettingsPalette.tabBarBackground.color.ignoresSafeArea(.container, edges: .top))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SettingsPalette.tabBarSeparator.color)
                .frame(height: 1)
        }
    }
}

/// One tab: its symbol over its title, on the island's black once chosen.
private struct SettingsTabButton: View {
    private static let symbolSize: CGFloat = 16
    private static let titleSize: CGFloat = 11
    private static let minimumWidth: CGFloat = 72
    private static let height: CGFloat = 46
    private static let horizontalPadding: CGFloat = 8
    private static let cornerRadius: CGFloat = 10

    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: Self.symbolSize))
                    .foregroundStyle(isSelected ? SettingsPalette.selectedTabSymbol : SettingsPalette.tabTitle.color)
                    .frame(height: Self.symbolSize + 4)
                // Sized by the semibold title whichever weight is drawn, so
                // choosing a tab never nudges the centred bar sideways.
                Text(tab.displayName)
                    .font(.system(size: Self.titleSize, weight: .semibold))
                    .hidden()
                    .overlay {
                        Text(tab.displayName)
                            .font(.system(size: Self.titleSize, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color.white : SettingsPalette.tabTitle.color)
                    }
                    .lineLimit(1)
            }
            .padding(.horizontal, Self.horizontalPadding)
            .frame(minWidth: Self.minimumWidth, minHeight: Self.height)
            .background {
                if isSelected {
                    selectedBackground
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var selectedBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        return shape
            .fill(SettingsPalette.selectedTabBackground)
            .overlay(shape.strokeBorder(SettingsPalette.selectedTabRim.color, lineWidth: 1))
            .shadow(color: SettingsPalette.selectedTabShadow.color, radius: 3, y: 1)
    }
}
