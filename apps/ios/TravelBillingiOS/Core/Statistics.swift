import Foundation

public struct CategorySummary: Codable, Hashable {
    public let category: BillCategory
    public let total: Decimal
    public let count: Int
}

public struct DailySummary: Codable, Hashable {
    public let date: Date
    public let total: Decimal
    public let count: Int
}

public enum Statistics {
    public static func summarizeByCategory(for trip: Trip) -> [CategorySummary] {
        var map: [BillCategory: (Decimal, Int)] = [:]
        for bill in trip.bills {
            let current = map[bill.category] ?? (0, 0)
            map[bill.category] = (current.0 + bill.amount, current.1 + 1)
        }
        return BillCategory.allCases.compactMap { cat in
            if let (sum, cnt) = map[cat] {
                return CategorySummary(category: cat, total: sum, count: cnt)
            }
            return nil
        }.sorted { $0.total > $1.total }
    }
    
    public static func summarizeDaily(for trip: Trip, in calendar: Calendar = .current) -> [DailySummary] {
        var map: [Date: (Decimal, Int)] = [:]
        for bill in trip.bills {
            let day = calendar.startOfDay(for: bill.date)
            let current = map[day] ?? (0, 0)
            map[day] = (current.0 + bill.amount, current.1 + 1)
        }
        return map.keys.sorted().map { day in
            let value = map[day]!
            return DailySummary(date: day, total: value.0, count: value.1)
        }
    }
}
