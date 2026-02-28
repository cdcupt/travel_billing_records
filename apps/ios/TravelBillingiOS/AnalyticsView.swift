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
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textSecondary.opacity(0.3))
                    Text("暂无数据")
                        .font(Theme.subheadlineFont())
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(byCat, id: \.category) { item in
                    BarMark(
                        x: .value("类别", item.category.displayName),
                        y: .value("金额(CNY)", item.total)
                    )
                    .foregroundStyle(Theme.primary.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(preset: .aligned, position: .bottom) { _ in
                        AxisValueLabel()
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.1))
                        AxisValueLabel()
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }
}
