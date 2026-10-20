import AppKit
import SwiftUI

/// The settings window's link to its `NSWindow`, which SwiftUI's `Settings`
/// scene creates without handing it out: it reports the height of the screen
/// the window is on, so a pane can be capped to fit it, and on macOS 14 it
/// hides the title bar, which SwiftUI does itself from macOS 15.
///
/// The window's appearance is deliberately left alone. It inherits the
/// system's, so the window turns light or dark with macOS and the palette's
/// dynamic colours follow it — which is why KerNotch has no appearance setting
/// to ask the user about.
struct SettingsWindowChrome: NSViewRepresentable {
    /// Called with the height of the visible part of the window's screen when
    /// the window appears and whenever it moves to another screen.
    let onScreenHeightChange: (CGFloat) -> Void

    func makeNSView(context: Context) -> WindowObservingView {
        WindowObservingView(onScreenHeightChange: onScreenHeightChange)
    }

    func updateNSView(_ nsView: WindowObservingView, context: Context) {
        nsView.onScreenHeightChange = onScreenHeightChange
    }

    /// The tab bar in the title bar's place, with the traffic lights inside it.
    static func apply(to window: NSWindow) {
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
    }

    final class WindowObservingView: NSView {
        var onScreenHeightChange: (CGFloat) -> Void
        private var screenObserver: (any NSObjectProtocol)?

        init(onScreenHeightChange: @escaping (CGFloat) -> Void) {
            self.onScreenHeightChange = onScreenHeightChange
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            return nil
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let screenObserver {
                NotificationCenter.default.removeObserver(screenObserver)
            }
            screenObserver = nil
            guard let window else { return }

            screenObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didChangeScreenNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.reportScreenHeight() }
            }
            // Deferred to the next pass of the run loop: the scene is still
            // configuring the window while its content moves in, and changing
            // the style mask or publishing state mid-update re-enters
            // SwiftUI's layout.
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                if #unavailable(macOS 15.0) {
                    SettingsWindowChrome.apply(to: window)
                }
                self.reportScreenHeight()
            }
        }

        private func reportScreenHeight() {
            guard let height = window?.screen?.visibleFrame.height else { return }
            onScreenHeightChange(height)
        }
    }
}
