import SwiftUI

enum DS {
    static let accent = Color(red: 0.38, green: 0.72, blue: 1.0)
    static let accent2 = Color(red: 0.66, green: 0.46, blue: 1.0)
    static let bg = Color(nsColor: .windowBackgroundColor)
    static let panel = Color.black.opacity(0.06)
    static let panel2 = Color.black.opacity(0.12)

    static func gradient(_ reverse: Bool = false) -> LinearGradient {
        LinearGradient(colors: reverse ? [accent2, accent] : [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct Glow: ViewModifier {
    var color: Color = DS.accent
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.45), radius: 12, x: 0, y: 0)
            .shadow(color: color.opacity(0.25), radius: 24, x: 0, y: 0)
    }
}

extension View {
    func glow(_ color: Color = DS.accent) -> some View { modifier(Glow(color: color)) }
}

