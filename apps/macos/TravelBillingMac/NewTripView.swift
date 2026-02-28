import SwiftUI

struct NewTripView: View {
    var onSave: (Trip) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var currency: String = "CNY"
    @State private var exchangeRate: Double = 1.0
    
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
                    .onChange(of: currency) { newCurrency in
                        let rates = UserDefaults.standard.dictionary(forKey: "exchangeRates") as? [String: Double]
                        if let r = rates?[newCurrency] {
                            exchangeRate = r
                        } else {
                            exchangeRate = 1.0
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
                    let t = Trip(name: name, startDate: startDate, endDate: endDate, currency: currency, exchangeRate: exchangeRate)
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
