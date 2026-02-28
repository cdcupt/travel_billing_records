import SwiftUI

struct TripDetailView: View {
    @State var trip: Trip
    var onUpdate: (Trip) -> Void
    @State private var showAdd = false
    @State private var showImage = false
    
    // State for pre-filling AddBillView from image recognition
    @State private var recognizedAmount: Decimal?
    @State private var recognizedDate: Date?
    @State private var recognizedNote: String?
    @State private var showAddWithRecognition = false
    
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
                            if trip.bills.isEmpty {
                                Button {
                                    showAdd = true
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
                            ForEach(trip.bills) { bill in
                                BillRowView(bill: bill, trip: trip)
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
        .navigationTitle(trip.name)
        .toolbar {
            Menu {
                Button {
                    showAdd = true
                } label: {
                    Label("手动添加", systemImage: "square.and.pencil")
                }
                Button {
                    showImage = true
                } label: {
                    Label("拍照记账", systemImage: "camera")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.primary)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddBillView(tripId: trip.id, currency: trip.currency) { bill in
                trip.addBill(bill)
                onUpdate(trip)
            }
        }
        .sheet(isPresented: $showAddWithRecognition) {
            AddBillView(
                tripId: trip.id,
                currency: trip.currency,
                initialAmount: recognizedAmount,
                initialDate: recognizedDate,
                initialNote: recognizedNote
            ) { bill in
                trip.addBill(bill)
                onUpdate(trip)
            }
        }
        .sheet(isPresented: $showImage) {
            ImageImportView { text in
                let importer = SimpleTextImporter()
                do {
                    let candidate = try importer.importText(text)
                    recognizedAmount = candidate.amount
                    recognizedDate = Date()
                    recognizedNote = ""
                    
                    if let amount = candidate.amount {
                        // debugMessage = "识别成功！\n金额: \(amount)\n原始文本片段: \(text.prefix(20))..."
                    } else {
                        // debugMessage = "未能识别出金额。\n原始文本片段: \(text.prefix(50))..."
                    }
                    // showDebugAlert = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAddWithRecognition = true
                    }
                } catch {
                    // debugMessage = "识别出错: \(error.localizedDescription)"
                    // showDebugAlert = true
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
