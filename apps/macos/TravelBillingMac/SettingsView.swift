import SwiftUI

extension Notification.Name {
    static let exchangeRatesUpdated = Notification.Name("ExchangeRatesUpdated")
}

final class SettingsStore: ObservableObject {
    @Published var defaultCurrency: String {
        didSet {
            UserDefaults.standard.set(defaultCurrency, forKey: "defaultCurrency")
            NotificationCenter.default.post(name: .exchangeRatesUpdated, object: nil)
        }
    }
    @Published var rates: [String: Double] {
        didSet {
            UserDefaults.standard.set(rates, forKey: "exchangeRates")
            NotificationCenter.default.post(name: .exchangeRatesUpdated, object: nil)
        }
    }
    init() {
        defaultCurrency = UserDefaults.standard.string(forKey: "defaultCurrency") ?? "CNY"
        let defaults: [String: Double] = [
            "CNY": 1.0, 
            "USD": 7.2, 
            "EUR": 7.8, 
            "JPY": 0.05, 
            "HKD": 0.9, 
            "THB": 0.2, 
            "KRW": 0.0053,
            "TWD": 0.23,
            "GBP": 9.2,
            "CHF": 8.1,
            "AUD": 4.7
        ]
        rates = UserDefaults.standard.dictionary(forKey: "exchangeRates") as? [String: Double] ?? defaults
    }
    
    func refreshRates() {
        guard let url = URL(string: "https://api.exchangerate.host/latest?base=CNY") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dict = json["rates"] as? [String: Double] else { return }
            
            // Convert "1 CNY = x Foreign" to "1 Foreign = x CNY"
            var newRates: [String: Double] = [:]
            for (code, rate) in dict {
                if rate > 0 {
                    newRates[code] = 1.0 / rate
                }
            }
            newRates["CNY"] = 1.0
            
            DispatchQueue.main.async {
                self.rates = newRates
            }
        }.resume()
    }
}

struct SettingsView: View {
    @StateObject var store = SettingsStore()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Form {
                Section("汇率 (1 外币 = x CNY)") {
                    ForEach(store.rates.keys.sorted(), id: \.self) { code in
                        HStack {
                            Text(code)
                            Spacer()
                            TextField("汇率", value: Binding(
                                get: { store.rates[code] ?? 0 },
                                set: { store.rates[code] = $0 }
                            ), format: .number)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    HStack {
                        Button("从网络更新最新汇率") { store.refreshRates() }
                        Spacer()
                        Menu("新增币种") {
                            Button("韩元 (KRW)") { store.rates["KRW"] = 0.0053 }
                            Button("港币 (HKD)") { store.rates["HKD"] = 0.92 }
                            Button("台币 (TWD)") { store.rates["TWD"] = 0.23 }
                            Button("英镑 (GBP)") { store.rates["GBP"] = 9.2 }
                            Button("瑞士法郎 (CHF)") { store.rates["CHF"] = 8.1 }
                            Button("澳元 (AUD)") { store.rates["AUD"] = 4.7 }
                            Button("自定义") { store.rates["NEW"] = 1.0 }
                        }
                    }
                }
                Section("默认币种") {
                    Picker("币种", selection: $store.defaultCurrency) {
                        ForEach(store.rates.keys.sorted(), id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }
            }
            .padding()
            
            HStack {
                Spacer()
                Button("完成") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 420, minHeight: 480)
    }
}
