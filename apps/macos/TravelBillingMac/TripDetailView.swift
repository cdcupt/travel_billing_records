import SwiftUI

struct TripDetailView: View {
    @State var trip: Trip
    var onUpdate: (Trip) -> Void
    @State private var showAdd = false
    
    var body: some View {
        List {
            Section("操作") {
                Button {
                    showAdd = true
                } label: {
                    Text("添加账单")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
            }
            Section("汇总") {
                let total = NSDecimalNumber(decimal: trip.totalAmount).doubleValue
                let totalText = String(format: "%.2f", total)
                Text("总开销 ¥\(totalText) CNY (汇率: 1 \(trip.currency) = \(trip.exchangeRate) CNY)")
            }
            Section("账单") {
                ForEach(trip.bills) { bill in
                    VStack(alignment: .leading) {
                        let rate = (bill.currency == trip.currency || bill.currency == nil) ? trip.exchangeRate : 1.0
                        let cny = NSDecimalNumber(decimal: bill.amount).doubleValue * rate
                        let cnyText = String(format: "%.2f", cny)
                        HStack {
                            Text("\(bill.category.rawValue) - ¥\(cnyText) CNY")
                        }
                        if let note = bill.note {
                            Text(note).foregroundColor(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("删除") {
                            if let idx = trip.bills.firstIndex(of: bill) {
                                trip.bills.remove(at: idx)
                                onUpdate(trip)
                            }
                        }
                    }
                }
                if trip.bills.isEmpty {
                    Button {
                        showAdd = true
                    } label: {
                        Text("添加第一条账单")
                    }
                }
            }
            Section("图表") {
                AnalyticsView(trip: trip)
                    .frame(height: 240)
            }
        }
        .navigationTitle(trip.name)
        .toolbar {
            Button("添加账单") { showAdd = true }
        }
        .sheet(isPresented: $showAdd) {
            AddBillView(tripId: trip.id, currency: trip.currency) { bill in
                trip.addBill(bill)
                onUpdate(trip)
            }
            .frame(minWidth: 480, minHeight: 520)
        }
    }
}
