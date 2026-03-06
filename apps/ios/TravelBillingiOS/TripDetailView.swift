import SwiftUI
import UIKit

struct TripDetailView: View {
    @State var trip: Trip
    var onUpdate: (Trip) -> Void
    @State private var showImage = false
    
    // State for pre-filling AddBillView from image recognition
    @State private var showAddWithRecognition = false
    
    // State for viewing bill detail
    @State private var selectedBill: Bill?
    @State private var showBillDetail = false
    @State private var sortOrder: SortOrder = .amountHighToLow
    
    // Use an ObservableObject to hold the recognized image so it persists across view updates
    class RecognitionState: ObservableObject {
        @Published var image: UIImage?
        @Published var amount: Decimal?
        @Published var date: Date?
        @Published var note: String?
        
        func reset() {
            image = nil
            amount = nil
            date = nil
            note = nil
        }
    }
    @StateObject private var recognitionState = RecognitionState()
    
    enum SortOrder: String, CaseIterable {
        case dateNewToOld = "日期 (最新优先)"
        case dateOldToNew = "日期 (最早优先)"
        case amountHighToLow = "金额 (从高到低)"
        case amountLowToHigh = "金额 (从低到高)"
    }
    
    // Temporary debug state
    @State private var showDebugAlert = false
    @State private var debugMessage = ""
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Card
                    VStack(spacing: 16) {
                        Text("总开销")
                            .font(Theme.subheadlineFont())
                            .foregroundColor(Theme.textSecondary)
                        
                        let totalCNY = NSDecimalNumber(decimal: trip.totalAmount).doubleValue
                        Text("¥\(totalCNY, specifier: "%.2f")")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primary)
                        
                        if trip.currency != "CNY" {
                            let totalOriginal = trip.bills
                                .filter { $0.currency == trip.currency }
                                .reduce(0) { $0 + $1.amount }
                            let totalOriginalVal = NSDecimalNumber(decimal: totalOriginal).doubleValue
                            
                            Text("原币种: \(totalOriginalVal, specifier: "%.2f") \(trip.currency)")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        HStack {
                            Text("汇率参考: 1 \(trip.currency) = \(trip.exchangeRate) CNY")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                                .padding(8)
                                .background(Theme.background)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                    .padding(.horizontal)
                    
                    // Chart Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("支出分析")
                            .font(Theme.headlineFont())
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal)
                        
                        AnalyticsView(trip: trip)
                            .frame(height: 220)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(Theme.cornerRadius)
                            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
                            .padding(.horizontal)
                    }
                    
                    // Bills List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("账单明细")
                                .font(Theme.headlineFont())
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            
                            Menu {
                                Picker("排序方式", selection: $sortOrder) {
                                    ForEach(SortOrder.allCases, id: \.self) { order in
                                        Text(order.rawValue).tag(order)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(Theme.primary)
                            }
                            
                            if trip.bills.isEmpty {
                                Button {
                                    showImage = true
                                } label: {
                                    Text("添加第一笔")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            let sortedBills = trip.bills.sorted { b1, b2 in
                                switch sortOrder {
                                case .dateNewToOld: return b1.date > b2.date
                                case .dateOldToNew: return b1.date < b2.date
                                case .amountHighToLow: 
                                    let v1 = b1.amount * Decimal(b1.currency == trip.currency ? 1.0 : (1.0/trip.exchangeRate))
                                    let v2 = b2.amount * Decimal(b2.currency == trip.currency ? 1.0 : (1.0/trip.exchangeRate))
                                    return v1 > v2
                                case .amountLowToHigh:
                                    let v1 = b1.amount * Decimal(b1.currency == trip.currency ? 1.0 : (1.0/trip.exchangeRate))
                                    let v2 = b2.amount * Decimal(b2.currency == trip.currency ? 1.0 : (1.0/trip.exchangeRate))
                                    return v1 < v2
                                }
                            }
                            
                            ForEach(sortedBills) { bill in
                                BillRowView(bill: bill, trip: trip)
                                    .contentShape(Rectangle()) // Make entire row tappable
                                    .onTapGesture {
                                        // Always use the latest bill object from the trip's bill list
                                        // This ensures we have the imagePath if it was just loaded
                                        if let freshBill = trip.bills.first(where: { $0.id == bill.id }) {
                                            selectedBill = freshBill
                                        } else {
                                            selectedBill = bill
                                        }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if let index = trip.bills.firstIndex(where: { $0.id == bill.id }) {
                                                trip.bills.remove(at: index)
                                                onUpdate(trip)
                                            }
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            if let index = trip.bills.firstIndex(where: { $0.id == bill.id }) {
                                                trip.bills.remove(at: index)
                                                onUpdate(trip)
                                            }
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
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
            // Force refresh when view appears to handle "first time load" issues
            // This fixes the issue where image paths might not be loaded on first entry
            let reloadedTrips = Persistence.shared.loadTrips()
            if let reloadedTrip = reloadedTrips.first(where: { $0.id == trip.id }) {
                self.trip = reloadedTrip
            }
        }
        .navigationTitle(trip.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showImage = true
                } label: {
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
                // 1. Update local model immediately
                var updatedTrip = trip
                updatedTrip.addBill(bill)
                onUpdate(updatedTrip)
                
                // 2. Clear recognition state
                recognitionState.reset()
                
                // 3. Force reload trip from DB with delay to ensure image path persistence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let reloadedTrips = Persistence.shared.loadTrips()
                    if let reloadedTrip = reloadedTrips.first(where: { $0.id == trip.id }) {
                        self.trip = reloadedTrip
                        
                        // 4. If the just-added bill is being viewed, update selectedBill
                        if let freshBill = reloadedTrip.bills.first(where: { $0.id == bill.id }) {
                            // Only auto-select if user hasn't selected another one
                            // Actually, let's not auto-select, just ensure data is ready
                            print("Trip reloaded, fresh bill image path: \(freshBill.imagePath ?? "nil")")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showImage) {
            ImageImportView { image, text in
                // Reset state before setting new values
                recognitionState.reset()
                
                // Set new image
                recognitionState.image = image
                
                if let text = text {
                    let importer = SimpleTextImporter()
                    do {
                        let candidate = try importer.importText(text)
                        recognitionState.amount = candidate.amount
                        recognitionState.date = Date()
                        recognitionState.note = ""
                    } catch {
                        recognitionState.amount = nil
                        recognitionState.date = Date()
                        recognitionState.note = ""
                    }
                } else {
                    recognitionState.amount = nil
                    recognitionState.date = Date()
                    recognitionState.note = ""
                }
                
                // Slight delay to allow sheet to dismiss before presenting next one
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showAddWithRecognition = true
                }
            }
        }
        .sheet(item: $selectedBill) { bill in
            BillDetailView(bill: bill, onDelete: {
                if let index = trip.bills.firstIndex(where: { $0.id == bill.id }) {
                    var updatedTrip = trip
                    updatedTrip.bills.remove(at: index)
                    onUpdate(updatedTrip)
                    
                    // Force refresh to keep UI in sync
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let reloadedTrips = Persistence.shared.loadTrips()
                        if let reloadedTrip = reloadedTrips.first(where: { $0.id == trip.id }) {
                            self.trip = reloadedTrip
                        }
                    }
                }
                selectedBill = nil
            })
        }
        .onChange(of: trip) { newTrip in
            // When trip updates, update selectedBill if it's currently presented
            // This is crucial for showing the image immediately after adding a bill
            if let current = selectedBill {
                if let updated = newTrip.bills.first(where: { $0.id == current.id }) {
                    // Only update if the image path was missing and now is present, or general update
                    if selectedBill?.imagePath == nil && updated.imagePath != nil {
                        print("Updating selected bill with image path: \(updated.imagePath!)")
                        selectedBill = updated
                    } else if selectedBill != updated {
                        selectedBill = updated
                    }
                }
            }
        }
        .alert("识别结果调试", isPresented: $showDebugAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(debugMessage)
        }
    }
}

struct BillRowView: View {
    let bill: Bill
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Theme.background)
                    .frame(width: 44, height: 44)
                
                // You can replace these with actual category icons later
                Text(bill.category.displayName.prefix(1))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.category.displayName)
                    .font(Theme.headlineFont())
                    .foregroundColor(Theme.textPrimary)
                
                if let note = bill.note, !note.isEmpty {
                    Text(note)
                        .font(Theme.subheadlineFont())
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                let code = bill.currency ?? trip.currency
                let amount = NSDecimalNumber(decimal: bill.amount).doubleValue
                
                Text("\(amount, specifier: "%.2f") \(code)")
                    .font(Theme.headlineFont())
                    .foregroundColor(Theme.textPrimary)
                
                if code != "CNY" {
                    let rate = (code == trip.currency) ? trip.exchangeRate : 1.0
                    let cny = amount * rate
                    Text("≈ ¥\(cny, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }
}
