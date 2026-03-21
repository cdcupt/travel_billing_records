import SwiftUI
import UIKit
import PhotosUI
import Vision

struct TripDetailView: View {
    @State var trip: Trip
    var onUpdate: (Trip) -> Void
    @State private var showBillFlow = false
    @State private var selectedBill: Bill?
    @State private var showBillDetail = false
    @State private var sortOrder: SortOrder = .amountHighToLow

    enum SortOrder: String, CaseIterable {
        case dateNewToOld   = "日期 (最新优先)"
        case dateOldToNew   = "日期 (最早优先)"
        case amountHighToLow = "金额 (从高到低)"
        case amountLowToHigh = "金额 (从低到高)"
    }

    @State private var savedCount = 0

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ── Hero Summary ──
                    summaryCard
                        .padding(.horizontal)

                    // ── Chart ──
                    VStack(alignment: .leading, spacing: 10) {
                        Text("支出分析")
                            .font(Theme.headlineFont())
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal)

                        AnalyticsView(trip: trip)
                            .frame(height: 220)
                            .padding()
                            .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
                            .padding(.horizontal)
                    }

                    // ── Bills ──
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("账单明细")
                                .font(Theme.headlineFont())
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Menu {
                                Picker("排序方式", selection: $sortOrder) {
                                    ForEach(SortOrder.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(8)
                                    .glassEffect(.regular, in: .circle)
                            }
                            if trip.bills.isEmpty {
                                Button { showBillFlow = true } label: {
                                    Text("添加第一笔")
                                        .font(.caption.bold())
                                        .foregroundColor(Theme.primary)
                                }
                            }
                        }
                        .padding(.horizontal)

                        LazyVStack(spacing: 10) {
                            let sorted = sortedBills
                            ForEach(sorted) { bill in
                                BillRowView(bill: bill, trip: trip)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedBill = trip.bills.first(where: { $0.id == bill.id }) ?? bill
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if let idx = trip.bills.firstIndex(where: { $0.id == bill.id }) {
                                                trip.bills.remove(at: idx); onUpdate(trip)
                                            }
                                        } label: { Label("删除", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            let reloaded = Persistence.shared.loadTrips()
            if let t = reloaded.first(where: { $0.id == trip.id }) { trip = t }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showBillFlow = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .sheet(isPresented: $showBillFlow) {
            BillFlowView(trip: trip) { bills in
                var updated = trip
                for bill in bills { updated.addBill(bill) }
                onUpdate(updated)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let t = Persistence.shared.loadTrips().first(where: { $0.id == trip.id }) { trip = t }
                }
            }
        }
        .sheet(item: $selectedBill) { bill in
            BillDetailView(bill: bill, onDelete: {
                if let idx = trip.bills.firstIndex(where: { $0.id == bill.id }) {
                    var updated = trip; updated.bills.remove(at: idx); onUpdate(updated)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let t = Persistence.shared.loadTrips().first(where: { $0.id == trip.id }) { trip = t }
                    }
                }
                selectedBill = nil
            })
        }
        .onChange(of: trip) {
            if let current = selectedBill, let updated = trip.bills.first(where: { $0.id == current.id }) {
                if selectedBill != updated { selectedBill = updated }
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Text("总开销")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            let totalCNY = NSDecimalNumber(decimal: trip.totalAmount).doubleValue
            Text("¥\(totalCNY, specifier: "%.2f")")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 8) {
                Text("\(trip.bills.count) 笔账单")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: .capsule)

                if trip.currency != "CNY" {
                    Text("1 \(trip.currency) = \(trip.exchangeRate, specifier: "%.4g") CNY")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .glassEffect(.regular, in: .capsule)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
    }

    private var sortedBills: [Bill] {
        trip.bills.sorted { b1, b2 in
            switch sortOrder {
            case .dateNewToOld:    return b1.date > b2.date
            case .dateOldToNew:    return b1.date < b2.date
            case .amountHighToLow:
                let v1 = b1.amount * Decimal(b1.currency == trip.currency ? 1.0 : (1.0 / trip.exchangeRate))
                let v2 = b2.amount * Decimal(b2.currency == trip.currency ? 1.0 : (1.0 / trip.exchangeRate))
                return v1 > v2
            case .amountLowToHigh:
                let v1 = b1.amount * Decimal(b1.currency == trip.currency ? 1.0 : (1.0 / trip.exchangeRate))
                let v2 = b2.amount * Decimal(b2.currency == trip.currency ? 1.0 : (1.0 / trip.exchangeRate))
                return v1 < v2
            }
        }
    }
}

struct BillRowView: View {
    let bill: Bill
    let trip: Trip

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: bill.category.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(bill.category.color)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.tint(bill.category.color), in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(bill.category.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                if let note = bill.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(bill.date.formatted(.dateTime.month().day()))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                let code   = bill.currency ?? trip.currency
                let amount = NSDecimalNumber(decimal: bill.amount).doubleValue
                Text("\(amount, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(code)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - BillFlowView (batch import: pick → review → save)

struct RecognizedInvoice: Identifiable {
    let id = UUID()
    var image: UIImage
    var amount: Decimal?
    var date: Date?
    var note: String?
    var lineItems: [BillLineItem]
    var category: BillCategory
    var isProcessing: Bool = false
}

struct IdentifiableInt: Identifiable {
    let id: Int
    var value: Int { id }
    init(_ value: Int) { self.id = value }
}

struct BillFlowView: View {
    let trip: Trip
    var onSaveBills: ([Bill]) -> Void

    enum FlowStep {
        case pick       // camera or gallery
        case review     // list of recognized invoices
    }

    @Environment(\.dismiss) private var dismiss
    @State private var step: FlowStep = .pick
    @State private var savedCount = 0
    @State private var invoices: [RecognizedInvoice] = []
    @State private var editingIndex: IdentifiableInt?
    @State private var showMissingAmountAlert = false

    private var missingAmountCount: Int {
        invoices.filter { $0.amount == nil || $0.amount == 0 }.count
    }

    // For multi-select from gallery
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var processingCount = 0
    @State private var showCamera = false
    @State private var cameraImage: UIImage?

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            switch step {
            case .pick:
                pickStep
            case .review:
                reviewStep
            }
        }
        .presentationDetents([.large])
        .alert("有未填写金额的账单", isPresented: $showMissingAmountAlert) {
            Button("返回修改", role: .cancel) { }
            Button("仍然保存") { saveAllInvoices() }
        } message: {
            Text("部分账单金额未识别，金额将记为0。建议点击账单补充金额后再保存。")
        }
        .sheet(item: $editingIndex) { wrapper in
            if invoices.indices.contains(wrapper.value) {
                editStep(index: wrapper.value)
            }
        }
    }

    // MARK: - Pick step

    private var pickStep: some View {
        VStack(spacing: 0) {
            if savedCount > 0 {
                savedBanner
            }

            Spacer()
            VStack(spacing: 24) {
                Text("添加发票")
                    .font(Theme.titleFont())
                    .foregroundColor(Theme.textPrimary)

                Button {
                    showCamera = true
                } label: {
                    Label("拍照", systemImage: "camera.fill")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                PhotosPicker(selection: $selectedItems, maxSelectionCount: 20, matching: .images) {
                    Label("从相册选择 (可多选)", systemImage: "photo.on.rectangle.angled")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)

                if savedCount > 0 {
                    Button("完成") { dismiss() }
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
            }
            .padding(30)
            Spacer()
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $cameraImage)
        }
        .onChange(of: cameraImage) {
            if let cameraImage {
                processImage(cameraImage)
            }
        }
        .onChange(of: selectedItems) {
            guard !selectedItems.isEmpty else { return }
            processingCount = selectedItems.count
            let items = selectedItems
            withAnimation { step = .review }
            Task { await processSelectedItems(items) }
            selectedItems = []
        }
    }

    // MARK: - Review step

    private var reviewStep: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button { withAnimation { step = .pick } } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(10)
                        .glassEffect(.regular, in: .circle)
                }
                .buttonStyle(.plain)

                Text("识别结果")
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

            if processingCount > 0 {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("正在识别 \(processingCount) 张发票...")
                        .font(Theme.subheadlineFont())
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.vertical, 8)
            }

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(Array(invoices.enumerated()), id: \.element.id) { index, invoice in
                        invoiceRow(invoice: invoice, index: index)
                            .onTapGesture {
                                editingIndex = IdentifiableInt(index)
                            }
                    }
                    .onDelete { offsets in
                        invoices.remove(atOffsets: offsets)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }

            // Bottom buttons
            VStack(spacing: 10) {
                if missingAmountCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(missingAmountCount) 笔账单未识别金额，请点击补充")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 6)
                }

                Button {
                    if missingAmountCount > 0 {
                        showMissingAmountAlert = true
                    } else {
                        saveAllInvoices()
                    }
                } label: {
                    Text("全部保存 (\(invoices.count) 笔)")
                        .font(Theme.headlineFont())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .disabled(invoices.isEmpty)
                .opacity(invoices.isEmpty ? 0.5 : 1.0)

                Button {
                    withAnimation { step = .pick }
                } label: {
                    Label("继续添加", systemImage: "plus")
                        .font(Theme.subheadlineFont())
                        .foregroundColor(Theme.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 8)
        }
    }

    private func invoiceRow(invoice: RecognizedInvoice, index: Int) -> some View {
        HStack(spacing: 14) {
            Image(uiImage: invoice.image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                if let note = invoice.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                } else {
                    Text(invoice.category.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }

                HStack(spacing: 6) {
                    Image(systemName: invoice.category.icon)
                        .font(.caption)
                        .foregroundColor(invoice.category.color)
                    Text(invoice.category.displayName)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if let amount = invoice.amount, amount > 0 {
                    Text("\(NSDecimalNumber(decimal: amount).doubleValue, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                } else {
                    Label("请补充金额", systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                }
                Text(trip.currency)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }

            // Delete button
            Button {
                invoices.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }

    // MARK: - Edit step

    private func editStep(index: Int) -> some View {
        let invoice = invoices[index]
        return AddBillView(
            tripId: trip.id,
            currency: trip.currency,
            initialAmount: invoice.amount,
            initialDate: invoice.date,
            initialNote: invoice.note,
            initialImage: invoice.image,
            initialLineItems: invoice.lineItems,
            initialCategory: invoice.category,
            onSave: { bill in
                if invoices.indices.contains(index) {
                    invoices[index].amount = bill.amount
                    invoices[index].note = bill.note
                    invoices[index].date = bill.date
                    invoices[index].category = bill.category
                    invoices[index].lineItems = bill.lineItems
                }
            }
        )
    }

    // MARK: - Helpers

    private var savedBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("已保存 \(savedCount) 笔账单")
                .font(Theme.subheadlineFont())
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Button("完成") { dismiss() }
                .font(Theme.subheadlineFont().bold())
                .foregroundColor(Theme.primary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func processImage(_ image: UIImage) {
        let placeholder = RecognizedInvoice(image: image, amount: nil, date: Date(), note: nil,
                                            lineItems: [], category: .misc, isProcessing: true)
        invoices.append(placeholder)
        let insertedIndex = invoices.count - 1
        withAnimation { step = .review }

        recognizeInvoice(image: image) { result in
            if invoices.indices.contains(insertedIndex) {
                invoices[insertedIndex].amount = result.totalAmount
                invoices[insertedIndex].date = result.date ?? Date()
                invoices[insertedIndex].note = result.merchantName
                invoices[insertedIndex].category = result.suggestedCategory
                invoices[insertedIndex].lineItems = result.lineItems.map {
                    BillLineItem(description: $0.description, amount: $0.amount)
                }
                invoices[insertedIndex].isProcessing = false
            }
        }
    }

    private func processSelectedItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    let placeholder = RecognizedInvoice(image: uiImage, amount: nil, date: Date(), note: nil,
                                                       lineItems: [], category: .misc, isProcessing: true)
                    invoices.append(placeholder)
                }
                let idx = await MainActor.run { invoices.count - 1 }
                recognizeInvoice(image: uiImage) { result in
                    if invoices.indices.contains(idx) {
                        invoices[idx].amount = result.totalAmount
                        invoices[idx].date = result.date ?? Date()
                        invoices[idx].note = result.merchantName
                        invoices[idx].category = result.suggestedCategory
                        invoices[idx].lineItems = result.lineItems.map {
                            BillLineItem(description: $0.description, amount: $0.amount)
                        }
                        invoices[idx].isProcessing = false
                    }
                    processingCount -= 1
                }
            } else {
                await MainActor.run { processingCount -= 1 }
            }
        }
    }

    private func recognizeInvoice(image: UIImage, completion: @escaping (InvoiceResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = image.cgImage else {
                let fallback = InvoiceResult(merchantName: nil, date: nil, lineItems: [],
                                             totalAmount: nil, suggestedCategory: .misc, rawText: "")
                DispatchQueue.main.async { completion(fallback) }
                return
            }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let strings = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
                let fullText = strings.joined(separator: "\n")
                let parser = InvoiceParser()
                let result = parser.parse(ocrText: fullText)
                DispatchQueue.main.async { completion(result) }
            } catch {
                let fallback = InvoiceResult(merchantName: nil, date: nil, lineItems: [],
                                             totalAmount: nil, suggestedCategory: .misc, rawText: "")
                DispatchQueue.main.async { completion(fallback) }
            }
        }
    }

    private func saveAllInvoices() {
        var bills: [Bill] = []
        for invoice in invoices {
            var imagePath: String?
            if let data = invoice.image.jpegData(compressionQuality: 0.7) {
                let filename = UUID().uuidString + ".jpg"
                let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let url = URL(fileURLWithPath: dir).appendingPathComponent(filename)
                if (try? data.write(to: url)) != nil { imagePath = filename }
            }
            let bill = Bill(tripId: trip.id, date: invoice.date ?? Date(),
                           amount: invoice.amount ?? 0, currency: trip.currency,
                           category: invoice.category, note: invoice.note,
                           imagePath: imagePath, lineItems: invoice.lineItems)
            bills.append(bill)
        }
        onSaveBills(bills)
        savedCount = bills.count
        invoices.removeAll()
        dismiss()
    }
}
