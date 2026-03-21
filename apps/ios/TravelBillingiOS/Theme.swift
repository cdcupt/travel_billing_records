import SwiftUI

struct Theme {
    static let primary  = Color(red: 0.20, green: 0.45, blue: 0.90)
    static let accent   = Color(red: 0.55, green: 0.30, blue: 0.88)

    static let textPrimary   = Color.black
    static let textSecondary = Color.black.opacity(0.55)

    // Legacy
    static let cardBackground = Color.white
    static let background     = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let shadowColor    = Color.black.opacity(0.08)
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat      = 4
    static let cornerRadius: CGFloat = 20

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.88, green: 0.93, blue: 1.00),
            Color(red: 0.93, green: 0.89, blue: 0.98),
            Color(red: 0.89, green: 0.97, blue: 0.93)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func titleFont()       -> Font { .system(size: 28, weight: .bold,     design: .rounded) }
    static func headlineFont()    -> Font { .system(size: 18, weight: .semibold, design: .rounded) }
    static func bodyFont()        -> Font { .system(size: 16, weight: .regular,  design: .rounded) }
    static func subheadlineFont() -> Font { .system(size: 14, weight: .medium,   design: .rounded) }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
    }

    func appBackground() -> some View {
        self.background(Theme.backgroundGradient.ignoresSafeArea())
    }
}
