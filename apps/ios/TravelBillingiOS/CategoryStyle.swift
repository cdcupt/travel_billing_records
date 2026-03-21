import SwiftUI

extension BillCategory {
    var icon: String {
        switch self {
        case .transport:     return "airplane"
        case .accommodation: return "bed.double.fill"
        case .food:          return "fork.knife"
        case .shopping:      return "bag.fill"
        case .entertainment: return "sparkles"
        case .tickets:       return "ticket.fill"
        case .tips:          return "hands.and.sparkles.fill"
        case .misc:          return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .transport:     return Color(red: 0.38, green: 0.64, blue: 1.00)
        case .accommodation: return Color(red: 0.72, green: 0.48, blue: 1.00)
        case .food:          return Color(red: 1.00, green: 0.58, blue: 0.28)
        case .shopping:      return Color(red: 1.00, green: 0.38, blue: 0.68)
        case .entertainment: return Color(red: 1.00, green: 0.80, blue: 0.20)
        case .tickets:       return Color(red: 0.28, green: 0.85, blue: 0.78)
        case .tips:          return Color(red: 0.38, green: 0.88, blue: 0.55)
        case .misc:          return Color.white.opacity(0.55)
        }
    }
}
