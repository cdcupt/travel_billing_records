import SwiftUI
import Charts

struct AnalyticsView: View {
    var trip: Trip

    var body: some View {
        VStack {
            let byCat = Dictionary(grouping: trip.bills) { $0.category }.map { (cat, bills) -> (category: BillCategory, total: Double) in
                let sum = bills.reduce(0.0) { acc, b in
                    let rate = (b.currency == trip.currency || b.currency == nil) ? trip.exchangeRate : 1.0
                    return acc + NSDecimalNumber(decimal: b.amount).doubleValue * rate
                }
                return (category: cat, total: sum)
            }.sorted { $0.total > $1.total }
            
            if byCat.isEmpty {
                Text("暂无数据").foregroundColor(.secondary)
            } else {
                Chart(byCat, id: \.category) { item in
                    BarMark(
                        x: .value("类别", item.category.rawValue),
                        y: .value("金额(CNY)", item.total)
                    )
                }
            }
        }
    }
}
