import AppKit
import SwiftUI

/// Renders the UI offscreen to a PNG.
///
/// `screencapture` needs the Screen Recording permission, which a terminal session may not have.
/// `ImageRenderer` draws the SwiftUI hierarchy without touching the window server, so the layout
/// can be inspected from a headless run.
///
/// Caveat: `NSViewRepresentable` content does not render here, so the translucent window
/// material comes out transparent. Everything drawn by SwiftUI itself — the phase picker, the
/// countdown, the transport buttons — is faithful.
@MainActor
public enum PreviewRenderer {
    public static func render(to path: String, scale: CGFloat = 2) -> Bool {
        let model = AppModel()
        let view = ContentView(model: model)
            .frame(width: 720, height: 508)
            // An explicit colour: `.windowBackgroundColor` does not resolve outside a window.
            .background(Color(red: 0.13, green: 0.13, blue: 0.14))
            .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: view)
        renderer.scale = scale

        guard let cgImage = renderer.cgImage else { return false }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .png, properties: [:]) else { return false }
        return (try? data.write(to: URL(fileURLWithPath: path))) != nil
    }
}
