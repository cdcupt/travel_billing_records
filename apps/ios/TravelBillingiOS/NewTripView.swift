import SwiftUI

struct NewTripView: View {
    var onSave: (Trip) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsStore()
    @State private var name         = ""
    @State private var startDate    = Date()
    @State private var endDate      = Date()
    @State private var currency     = "CNY"
    @State private var exchangeRate = 1.0

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("新建旅行")
                        .font(Theme.titleFont())
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                            .padding(10)
                            .glassEffect(.regular, in: .circle)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 14) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("旅行名称")
                                .font(Theme.subheadlineFont())
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 24)
                            TextField("例：东京五日游", text: $name)
                                .font(Theme.bodyFont())
                                .foregroundColor(Theme.textPrimary)
                                .padding(16)
                                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                                .padding(.horizontal, 24)
                        }

                        // Dates
                        VStack(spacing: 10) {
                            HStack {
                                Text("开始日期")
                                    .font(Theme.subheadlineFont())
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            .padding(16)
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))

                            HStack {
                                Text("结束日期")
                                    .font(Theme.subheadlineFont())
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            .padding(16)
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        }
                        .padding(.horizontal, 24)

                        // Currency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("币种")
                                .font(Theme.subheadlineFont())
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 24)

                            HStack {
                                Text("选择币种")
                                    .font(Theme.bodyFont())
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                Picker("", selection: $currency) {
                                    ForEach(settings.rates.keys.sorted(), id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .colorScheme(.dark)
                                .onChange(of: currency) { newVal in
                                    exchangeRate = settings.rates[newVal] ?? 1.0
                                }
                            }
                            .padding(16)
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))
                            .padding(.horizontal, 24)

                            if currency != "CNY" {
                                HStack {
                                    Text("汇率 (1 \(currency) = x CNY)")
                                        .font(Theme.subheadlineFont())
                                        .foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    TextField("汇率", value: $exchangeRate, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Theme.textPrimary)
                                        .frame(width: 80)
                                }
                                .padding(16)
                                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }

                Button {
                    guard !name.isEmpty else { return }
                    onSave(Trip(name: name, startDate: startDate, endDate: endDate,
                                currency: currency, exchangeRate: exchangeRate))
                    dismiss()
                } label: {
                    Text("创建旅行")
                        .font(Theme.headlineFont())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .padding(.top, 8)
                .onAppear {
                    currency = settings.defaultCurrency
                    exchangeRate = settings.rates[currency] ?? 1.0
                }
            }
        }
        .presentationDetents([.large])
    }
}
