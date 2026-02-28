import SwiftUI

struct EditTripView: View {
    var trip: Trip
    var onSave: (Trip) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var currency: String
    @State private var exchangeRate: Double
    
    init(trip: Trip, onSave: @escaping (Trip) -> Void) {
        self.trip = trip
        self.onSave = onSave
        _name = State(initialValue: trip.name)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _currency = State(initialValue: trip.currency)
        _exchangeRate = State(initialValue: trip.exchangeRate)
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("名称", text: $name)
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                    Picker("币种", selection: $currency) {
                        let codes = ((UserDefaults.standard.dictionary(forKey: "exchangeRates") as? [String: Double])?.keys.map { String($0) } ?? ["CNY","USD","EUR","JPY","HKD"]).sorted()
                        ForEach(codes, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    if currency != "CNY" {
                        TextField("汇率 (1 \(currency) = x CNY)", value: $exchangeRate, format: .number)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Button("保存") {
                    var t = trip
                    t.name = name
                    t.startDate = startDate
                    t.endDate = endDate
                    t.currency = currency
                    t.exchangeRate = exchangeRate
                    onSave(t)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 420, minHeight: 360)
    }
}
