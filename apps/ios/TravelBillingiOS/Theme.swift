import SwiftUI

struct Theme {
    // Primary Color: A soft, warm teal/blue
    static let primary = Color(red: 0.25, green: 0.58, blue: 0.85)
    
    // Accent Color: A friendly coral/peach
    static let accent = Color(red: 1.0, green: 0.55, blue: 0.45)
    
    // Background Color: Very light gray/blue
    static let background = Color(red: 0.96, green: 0.97, blue: 0.99)
    
    // Card Background: Pure white
    static let cardBackground = Color.white
    
    // Text Colors
    static let textPrimary = Color(red: 0.2, green: 0.2, blue: 0.25)
    static let textSecondary = Color(red: 0.5, green: 0.55, blue: 0.6)
    
    // Shadow
    static let shadowColor = Color.black.opacity(0.08)
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 4
    
    // Corner Radius
    static let cornerRadius: CGFloat = 16
    
    // Font
    static func titleFont() -> Font {
        .system(size: 24, weight: .bold, design: .rounded)
    }
    
    static func headlineFont() -> Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }
    
    static func bodyFont() -> Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }
    
    static func subheadlineFont() -> Font {
        .system(size: 14, weight: .medium, design: .rounded)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }
    
    func appBackground() -> some View {
        self.background(Theme.background)
    }
}
