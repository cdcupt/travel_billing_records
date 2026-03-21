import SwiftUI
import UIKit

struct TripDetailView: View {
    @State var trip: Trip
    var onUpdate: (Trip) -> Void
    @State private var showImage = false
    @State private var showAddWithRecognition = false
    @State private var selectedBill: Bill?
    @State private var showBillDetail = false
    @State private var sortOrder: SortOrder = .amountHighToLow

    class RecognitionState: ObservableObject {
        @Published var image: UIImage?
        @Published var amount: Decimal?
        @Published var date: Date?
        @Published var note: String?
        func reset() { image = nil; amount = nil; date = nil; note = nil }
    }
    @StateObject private var recognitionState = RecognitionState()

    enum SortOrder: String, CaseIterable {
        case dateNewToOld   = "日期 (最新优先)"
        case dateOldToNew   = "日期 (最早优先)"
        case amountHighToLow = "金额 (从高到低)"
        case amountLowToHigh = "金额 (从低到高)"
    }

    @State private var showDebugAlert = false
    @State private var debugMessage   = ""

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
                                Button { showImage = true } label: {
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
                Button { showImage = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .sheet(isPresented: $showAddWithRecognition) {
            AddBillView(
                tripId: trip.id,
                currency: trip.currency,
                initialAmount: recognitionState.amount,
                initialDate: recognitionState.date,
                initialNote: recognitionState.note,
                initialImage: recognitionState.image
            ) { bill in
                var updated = trip; updated.addBill(bill); onUpdate(updated)
                recognitionState.reset()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let t = Persistence.shared.loadTrips().first(where: { $0.id == trip.id }) { trip = t }
                }
            }
        }
        .sheet(isPresented: $showImage) {
            ImageImportView { image, text in
                recognitionState.reset()
                recognitionState.image = image
                if let text {
                    let importer = SimpleTextImporter()
                    if let candidate = try? importer.importText(text) {
                        recognitionState.amount = candidate.amount
                    }
                }
                recognitionState.date = Date()
                recognitionState.note = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showAddWithRecognition = true }
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
        .onChange(of: trip) { newTrip in
            if let current = selectedBill, let updated = newTrip.bills.first(where: { $0.id == current.id }) {
                if selectedBill != updated { selectedBill = updated }
            }
        }
        .alert("识别结果调试", isPresented: $showDebugAlert) {
            Button("确定", role: .cancel) {}
        } message: { Text(debugMessage) }
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
