import SwiftUI
import UIKit

struct AddBillView: View {
    let tripId: UUID
    let currency: String
    let initialAmount: Decimal?
    let initialDate: Date?
    let initialNote: String?
    let initialImage: UIImage?
    let initialLineItems: [BillLineItem]
    let initialCategory: BillCategory?
    var onSave: (Bill) -> Void
    var onSaveAndContinue: ((Bill) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var amountText  = ""
    @State private var note        = ""
    @State private var date        = Date()
    @State private var category: BillCategory = .food
    @State private var invoiceImage: UIImage?
    @State private var lineItems: [BillLineItem] = []
    @State private var showLineItems = false
    @State private var showFullImage = false

    init(tripId: UUID, currency: String, initialAmount: Decimal? = nil, initialDate: Date? = nil,
         initialNote: String? = nil, initialImage: UIImage? = nil,
         initialLineItems: [BillLineItem] = [], initialCategory: BillCategory? = nil,
         onSave: @escaping (Bill) -> Void,
         onSaveAndContinue: ((Bill) -> Void)? = nil) {
        self.tripId = tripId; self.currency = currency
        self.initialAmount = initialAmount; self.initialDate = initialDate
        self.initialNote = initialNote; self.initialImage = initialImage
        self.initialLineItems = initialLineItems; self.initialCategory = initialCategory
        self.onSave = onSave; self.onSaveAndContinue = onSaveAndContinue
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
                        // Invoice image thumbnail (tap to zoom)
                        if let image = invoiceImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 2)
                                        .padding(8)
                                }
                                .padding(.horizontal, 24)
                                .onTapGesture { showFullImage = true }
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

                        // Line items
                        if !lineItems.isEmpty || showLineItems {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Button { withAnimation { showLineItems.toggle() } } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: showLineItems ? "chevron.down" : "chevron.right")
                                                .font(.caption.bold())
                                            Text("明细 (\(lineItems.count)项)")
                                                .font(Theme.subheadlineFont())
                                        }
                                        .foregroundColor(Theme.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                    if showLineItems {
                                        Button {
                                            lineItems.append(BillLineItem(description: "", amount: 0))
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(Theme.primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)

                                if showLineItems {
                                    VStack(spacing: 8) {
                                        ForEach(Array(lineItems.enumerated()), id: \.element.id) { index, item in
                                            HStack(spacing: 10) {
                                                TextField("项目名称", text: Binding(
                                                    get: { lineItems[safe: index]?.description ?? "" },
                                                    set: { if lineItems.indices.contains(index) { lineItems[index].description = $0 } }
                                                ))
                                                .font(Theme.bodyFont())
                                                .foregroundColor(Theme.textPrimary)

                                                TextField("0.00", text: Binding(
                                                    get: {
                                                        guard let item = lineItems[safe: index] else { return "" }
                                                        return item.amount == 0 ? "" : NSDecimalNumber(decimal: item.amount).stringValue
                                                    },
                                                    set: {
                                                        if lineItems.indices.contains(index) {
                                                            lineItems[index].amount = Decimal(string: $0) ?? 0
                                                        }
                                                    }
                                                ))
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(Theme.textPrimary)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                                .frame(width: 90)

                                                Button {
                                                    if lineItems.indices.contains(index) {
                                                        lineItems.remove(at: index)
                                                        recalcTotal()
                                                    }
                                                } label: {
                                                    Image(systemName: "minus.circle.fill")
                                                        .foregroundColor(.red.opacity(0.7))
                                                        .font(.system(size: 16))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(12)
                                            .glassEffect(.regular, in: .rect(cornerRadius: 12))
                                        }

                                        // Sum row
                                        HStack {
                                            Text("明细合计")
                                                .font(Theme.subheadlineFont())
                                                .foregroundColor(Theme.textSecondary)
                                            Spacer()
                                            let sum = lineItems.reduce(Decimal(0)) { $0 + $1.amount }
                                            Text("¥\(NSDecimalNumber(decimal: sum).doubleValue, specifier: "%.2f")")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(Theme.primary)
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.top, 4)

                                        Button {
                                            recalcTotal()
                                        } label: {
                                            Text("以明细合计更新总金额")
                                                .font(.caption.bold())
                                                .foregroundColor(Theme.primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }

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

                // Save buttons
                VStack(spacing: 10) {
                    if onSaveAndContinue != nil {
                        Button {
                            guard let bill = buildBill() else { return }
                            onSaveAndContinue?(bill)
                        } label: {
                            Label("保存并继续添加", systemImage: "camera.fill")
                                .font(Theme.headlineFont())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(amountText.isEmpty)
                        .opacity(amountText.isEmpty ? 0.5 : 1.0)
                    }

                    if onSaveAndContinue != nil {
                        Button {
                            guard let bill = buildBill() else { return }
                            onSave(bill)
                            dismiss()
                        } label: {
                            Text("保存完成")
                                .font(Theme.headlineFont())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.bordered)
                        .disabled(amountText.isEmpty)
                        .opacity(amountText.isEmpty ? 0.5 : 1.0)
                    } else {
                        Button {
                            guard let bill = buildBill() else { return }
                            onSave(bill)
                            dismiss()
                        } label: {
                            Text("保存账单")
                                .font(Theme.headlineFont())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(amountText.isEmpty)
                        .opacity(amountText.isEmpty ? 0.5 : 1.0)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .padding(.top, 8)
            }
        }
        .fullScreenCover(isPresented: $showFullImage) {
            if let image = invoiceImage {
                ZoomableImageView(image: image, onClose: { showFullImage = false })
            }
        }
        .presentationDetents([.large])
        .onAppear {
            if let v = initialAmount  { amountText   = NSDecimalNumber(decimal: v).stringValue }
            if let v = initialDate    { date          = v }
            if let v = initialNote    { note          = v }
            if let v = initialImage   { invoiceImage  = v }
            if let v = initialCategory { category     = v }
            if !initialLineItems.isEmpty {
                lineItems = initialLineItems
                showLineItems = true
            }
        }
    }

    private func buildBill() -> Bill? {
        guard let amount = Decimal(string: amountText) else { return nil }
        var imagePath: String?
        if let image = invoiceImage, let data = image.jpegData(compressionQuality: 0.7) {
            let filename = UUID().uuidString + ".jpg"
            let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let url = URL(fileURLWithPath: dir).appendingPathComponent(filename)
            if (try? data.write(to: url)) != nil { imagePath = filename }
        }
        return Bill(tripId: tripId, date: date, amount: amount, currency: currency,
                    category: category, participants: [], note: note, imagePath: imagePath,
                    lineItems: lineItems.filter { !$0.description.isEmpty || $0.amount > 0 })
    }

    private func recalcTotal() {
        let sum = lineItems.reduce(Decimal(0)) { $0 + $1.amount }
        if sum > 0 {
            amountText = NSDecimalNumber(decimal: sum).stringValue
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
