import SwiftUI

/// Liquid Glass, applied where it is available.
///
/// The whole API — `glassEffect(_:in:)`, `GlassEffectContainer`, `Glass.regular/.clear`,
/// `.tint(_:)`, `.interactive(_:)` — is `@available(macOS 26.0, *)`, while this app deploys back
/// to macOS 14. Rather than raising the deployment target and dropping older systems, each glass
/// surface degrades to the material it used before.
/// Whether Liquid Glass is used at all.
///
/// `glassEffect` is a live compositing effect: it does not rasterise through `ImageRenderer`,
/// and views carrying it come out blank in an offscreen render. That also makes it the one
/// piece of the UI that cannot be verified without looking at the running app, so it has an
/// escape hatch:
///
///     defaults write studio.visionlab.pomodorotimer debug.disableGlass -bool YES
@MainActor
enum GlassStyling {
    /// Set by the offscreen renderer, which cannot draw glass.
    static var forceDisabled = false

    static var isEnabled: Bool {
        if forceDisabled { return false }
        return !UserDefaults.standard.bool(forKey: "debug.disableGlass")
    }
}

extension View {
    /// A glass surface clipped to `shape`, falling back to `fallback` before macOS 26.
    @ViewBuilder
    func glassSurface(
        in shape: some Shape,
        tint: Color? = nil,
        interactive: Bool = false,
        fallback: some ShapeStyle = .regularMaterial
    ) -> some View {
        if #available(macOS 26.0, *), GlassStyling.isEnabled {
            // Built out of line: a ViewBuilder body cannot hold arbitrary statements.
            self.glassEffect(Glass.configured(tint: tint, interactive: interactive), in: shape)
        } else {
            self.background(shape.fill(fallback))
        }
    }
}

@available(macOS 26.0, *)
extension Glass {
    static func configured(tint: Color?, interactive: Bool) -> Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
}

/// `GlassEffectContainer` lets neighbouring glass shapes blend into one another instead of
/// stacking as separate panes. It does not exist before macOS 26, where the content is passed
/// through untouched.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat? = nil
    @ViewBuilder let content: Content

    var body: some View {
        if #available(macOS 26.0, *), GlassStyling.isEnabled {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
