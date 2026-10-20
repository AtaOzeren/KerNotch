import CoreGraphics
import SwiftUI

/// The settings window's fixed visual budget, shared by every pane so the tabs
/// do not drift apart in density — one edit changes all six.
///
/// This started as the AI Integrations pane's private metrics. It is shared
/// rather than copied because a settings window whose tabs disagree about
/// inset, type scale, or width visibly jumps as the user switches between them.
public struct SettingsPaneMetrics: Equatable, Sendable {
    public static let `default` = SettingsPaneMetrics()

    /// Space above the first row and below the last.
    public let verticalInset: CGFloat
    /// Space between the window's leading edge and the label column.
    public let leadingInset: CGFloat
    /// Space between the controls and the window's trailing edge.
    public let trailingInset: CGFloat
    /// Space between two rows, and either side of a divider.
    public let sectionSpacing: CGFloat
    /// Space between the pieces stacked inside one row.
    public let rowSpacing: CGFloat
    /// The width of the trailing-aligned column the row labels sit in.
    public let labelColumnWidth: CGFloat
    /// The gap between the label column and the controls.
    public let columnSpacing: CGFloat
    public let bodySize: CGFloat
    public let footnoteSize: CGFloat
    /// Captions wrap at this width, so a line still reads at a glance.
    public let captionWidth: CGFloat
    public let width: CGFloat
    /// The tallest a pane grows under the tab bar before it scrolls. Below it
    /// the window fits each pane, the way a macOS settings window resizes from
    /// tab to tab.
    public let maximumPaneHeight: CGFloat
    /// What the window needs on its screen besides the pane — the title bar,
    /// the tab bar, and a margin from the screen's edges.
    public let reservedScreenHeight: CGFloat
    /// The least a pane is cut to on a short screen, so it still shows a few
    /// rows to scroll through.
    public let minimumPaneHeight: CGFloat

    public init(
        verticalInset: CGFloat = 26,
        leadingInset: CGFloat = 20,
        trailingInset: CGFloat = 40,
        sectionSpacing: CGFloat = 16,
        rowSpacing: CGFloat = 8,
        labelColumnWidth: CGFloat = 170,
        columnSpacing: CGFloat = 12,
        bodySize: CGFloat = 13,
        footnoteSize: CGFloat = 11,
        captionWidth: CGFloat = 400,
        width: CGFloat = 680,
        maximumPaneHeight: CGFloat = 680,
        reservedScreenHeight: CGFloat = 130,
        minimumPaneHeight: CGFloat = 240
    ) {
        self.verticalInset = verticalInset
        self.leadingInset = leadingInset
        self.trailingInset = trailingInset
        self.sectionSpacing = sectionSpacing
        self.rowSpacing = rowSpacing
        self.labelColumnWidth = labelColumnWidth
        self.columnSpacing = columnSpacing
        self.bodySize = bodySize
        self.footnoteSize = footnoteSize
        self.captionWidth = captionWidth
        self.width = width
        self.maximumPaneHeight = maximumPaneHeight
        self.reservedScreenHeight = reservedScreenHeight
        self.minimumPaneHeight = minimumPaneHeight
    }

    /// The height a pane may take on a screen whose visible part is
    /// `screenHeight` tall: the window then fits that screen with the pane
    /// scrolling, as on a small display or a "Larger Text" resolution.
    /// Without a screen yet, the fixed ceiling.
    public func paneCeiling(onScreenOfHeight screenHeight: CGFloat?) -> CGFloat {
        guard let screenHeight else { return maximumPaneHeight }
        return min(maximumPaneHeight, max(minimumPaneHeight, screenHeight - reservedScreenHeight))
    }
}

/// One row of a settings pane: a trailing-aligned label in the left column,
/// the row's controls in the right one, and an optional caption under them —
/// the one row shape every pane uses, so the label column lines up across a
/// pane and across tabs.
///
/// Toggles inside a row draw as checkboxes in KerNotch's green: the classic
/// macOS form this layout comes from pairs a label column with checkboxes,
/// where switches would each claim a row of their own.
struct SettingsFormRow<Content: View>: View {
    private let label: String
    private let caption: String?
    private let metrics: SettingsPaneMetrics
    private let content: Content

    init(
        _ label: String,
        caption: String? = nil,
        metrics: SettingsPaneMetrics = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.caption = caption
        self.metrics = metrics
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: metrics.columnSpacing) {
            Text(settingsFormLabel(label))
                .font(.system(size: metrics.bodySize))
                .foregroundStyle(SettingsPalette.rowLabel.color)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: metrics.labelColumnWidth, alignment: .trailing)
            VStack(alignment: .leading, spacing: metrics.rowSpacing) {
                content
                if let caption {
                    SettingsCaption(caption, metrics: metrics)
                }
            }
            .font(.system(size: metrics.bodySize))
            .toggleStyle(SettingsCheckboxStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A native checkbox in KerNotch's green.
///
/// The tint is applied to the checkbox alone rather than to the row: a tint on
/// the row would also colour the text of its pop-up buttons, which stay in the
/// system's own neutral colours.
struct SettingsCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .toggleStyle(.checkbox)
            .tint(SettingsPalette.accent)
    }
}

extension View {
    /// A segmented picker as the form draws one: at its own width, its label
    /// left to the row, its selection in KerNotch's green like the checkboxes.
    func settingsSegmentedPicker() -> some View {
        pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .tint(SettingsPalette.accent)
    }
}

/// The explanation under a row's controls, in the caption tone of the
/// appearance the window is in.
struct SettingsCaption: View {
    private let text: String
    private let metrics: SettingsPaneMetrics

    init(_ text: String, metrics: SettingsPaneMetrics = .default) {
        self.text = text
        self.metrics = metrics
    }

    var body: some View {
        Text(text)
            .font(.system(size: metrics.footnoteSize))
            .foregroundStyle(SettingsPalette.caption.color)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: metrics.captionWidth, alignment: .leading)
    }
}

/// The hairline between two groups of rows.
struct SettingsFormDivider: View {
    var body: some View {
        Rectangle()
            .fill(SettingsPalette.separator.color)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// The warning General and About both raise while a changed language waits
/// for a restart.
struct SettingsRestartNotice: View {
    var body: some View {
        Label(localized("Restart required"), systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(SettingsPalette.warning.color)
    }
}

/// A row label as the form shows it: the title followed by the colon, spaced
/// the way the user's language spaces one ("Display:", but "Écran :").
func settingsFormLabel(_ title: String) -> String {
    localized("settings.form.label", default: "\(title):")
}

extension View {
    /// The frame every pane sits in, so a tab switch never moves the label
    /// column.
    ///
    /// It fills the width it is offered rather than claiming the window's: a
    /// scroll bar shown permanently (a mouse attached, or the "Always" scroll
    /// bar setting) narrows the scroll view, and a fixed width would then run
    /// under it.
    func settingsPaneFrame(_ metrics: SettingsPaneMetrics) -> some View {
        padding(.top, metrics.verticalInset)
            .padding(.bottom, metrics.verticalInset)
            .padding(.leading, metrics.leadingInset)
            .padding(.trailing, metrics.trailingInset)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

/// Sizes the pane's scroll view to the pane it holds, up to a ceiling, whatever
/// height the window offers.
///
/// A scroll view takes any height it is given, so a `Settings` window would
/// otherwise open at a height of its own choosing and scroll a pane that fits.
/// Reporting the pane's own height as the only size it accepts makes the window
/// fit each tab; the ceiling, `SettingsPaneMetrics.paneCeiling`, keeps the
/// window on its screen and lets a pane taller than that scroll.
struct SettingsPaneFitting: Layout {
    let maximumHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        let ideal = content.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        return CGSize(width: proposal.width ?? ideal.width, height: min(ideal.height, maximumHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}
