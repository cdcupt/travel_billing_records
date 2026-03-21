import SwiftUI
import UIKit

struct AddBillView: View {
    let tripId: UUID
    let currency: String
    let initialAmount: Decimal?
    let initialDate: Date?
    let initialNote: String?
    let initialImage: UIImage?
    var onSave: (Bill) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText  = ""
    @State private var note        = ""
    @State private var date        = Date()
    @State private var category: BillCategory = .food
    @State private var invoiceImage: UIImage?

    init(tripId: UUID, currency: String, initialAmount: Decimal? = nil, initialDate: Date? = nil,
         initialNote: String? = nil, initialImage: UIImage? = nil, onSave: @escaping (Bill) -> Void) {
        self.tripId = tripId; self.currency = currency
        self.initialAmount = initialAmount; self.initialDate = initialDate
        self.initialNote = initialNote; self.initialImage = initialImage
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("添加账单")
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
                .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 20) {
                        // Invoice image
                        if let image = invoiceImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                                .padding(.horizontal, 24)
                        }

                        // Amount hero
                        VStack(spacing: 6) {
                            Text("金额 (\(currency))")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            TextField("0.00", text: $amountText)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
                        .padding(.horizontal, 24)

                        // Category grid
                        VStack(alignment: .leading, spacing: 10) {
                            Text("类别")
                                .font(Theme.subheadlineFont())
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 24)

                            GlassEffectContainer(spacing: 10) {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                                    ForEach(BillCategory.allCases, id: \.self) { cat in
                                        Button { category = cat } label: {
                                            VStack(spacing: 6) {
                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundColor(category == cat ? cat.color : Theme.textSecondary)
                                                Text(cat.displayName)
                                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                                    .foregroundColor(category == cat ? cat.color : Theme.textSecondary)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.7)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                        }
                                        .buttonStyle(.plain)
                                        .glassEffect(
                                            category == cat
                                                ? .regular.tint(cat.color).interactive()
                                                : .regular.interactive(),
                                            in: .rect(cornerRadius: 14)
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        // Date + Note
                        VStack(spacing: 12) {
                            HStack {
                                Text("日期")
                                    .font(Theme.subheadlineFont())
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            .padding(16)
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))

                            TextField("添加备注...", text: $note)
                                .font(Theme.bodyFont())
                                .foregroundColor(Theme.textPrimary)
                                .padding(16)
                                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 20)
                }

                // Save button
                Button {
                    guard let amount = Decimal(string: amountText) else { return }
                    var imagePath: String?
                    if let image = invoiceImage, let data = image.jpegData(compressionQuality: 0.7) {
                        let filename = UUID().uuidString + ".jpg"
                        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let url = URL(fileURLWithPath: dir).appendingPathComponent(filename)
                        if (try? data.write(to: url)) != nil { imagePath = filename }
                    }
                    let bill = Bill(tripId: tripId, date: date, amount: amount, currency: currency,
                                   category: category, participants: [], note: note, imagePath: imagePath)
                    onSave(bill)
                    dismiss()
                } label: {
                    Text("保存账单")
                        .font(Theme.headlineFont())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .disabled(amountText.isEmpty)
                .opacity(amountText.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .padding(.top, 8)
            }
        }
        .presentationDetents([.large])
        .onAppear {
            if let v = initialAmount  { amountText   = NSDecimalNumber(decimal: v).stringValue }
            if let v = initialDate    { date          = v }
            if let v = initialNote    { note          = v }
            if let v = initialImage   { invoiceImage  = v }
        }
    }
}
