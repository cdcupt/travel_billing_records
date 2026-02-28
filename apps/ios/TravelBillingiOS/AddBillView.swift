import SwiftUI

struct AddBillView: View {
    let tripId: UUID
    let currency: String
    
    // Make these regular properties, not initial-only
    let initialAmount: Decimal?
    let initialDate: Date?
    let initialNote: String?
    
    var onSave: (Bill) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var category: BillCategory = .food
    
    init(tripId: UUID, currency: String, initialAmount: Decimal? = nil, initialDate: Date? = nil, initialNote: String? = nil, onSave: @escaping (Bill) -> Void) {
        self.tripId = tripId
        self.currency = currency
        self.initialAmount = initialAmount
        self.initialDate = initialDate
        self.initialNote = initialNote
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("添加一笔账单")
                        .font(Theme.titleFont())
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Amount Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("金额 (\(currency))")
                                .font(Theme.subheadlineFont())
                                .foregroundColor(Theme.textSecondary)
                            
                            TextField("0.00", text: $amountText)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(Theme.cornerRadius)
                                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
                        }
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("类别")
                                .font(Theme.subheadlineFont())
                                .foregroundColor(Theme.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(BillCategory.allCases, id: \.self) { cat in
                                        Button {
                                            category = cat
                                        } label: {
                                            Text(cat.displayName)
                                                .font(Theme.subheadlineFont())
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(category == cat ? Theme.primary : Theme.cardBackground)
                                                .foregroundColor(category == cat ? .white : Theme.textPrimary)
                                                .cornerRadius(20)
                                                .shadow(color: Theme.shadowColor, radius: 4, x: 0, y: 2)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Date Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("日期")
                                .font(Theme.subheadlineFont())
                                .foregroundColor(Theme.textSecondary)
                            
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(Theme.cornerRadius)
                                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Note Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备注")
                                .font(Theme.subheadlineFont())
                                .foregroundColor(Theme.textSecondary)
                            
                            TextField("添加备注...", text: $note)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(Theme.cornerRadius)
                                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
                        }
                    }
                }
                
                // Save Button
                Button {
                    guard let amount = Decimal(string: amountText) else { return }
                    let bill = Bill(
                        tripId: tripId,
                        date: date,
                        amount: amount,
                        currency: currency,
                        category: category,
                        participants: [],
                        note: note
                    )
                    onSave(bill)
                    dismiss()
                } label: {
                    Text("保存账单")
                        .font(Theme.headlineFont())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primary)
                        .cornerRadius(Theme.cornerRadius)
                        .shadow(color: Theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(amountText.isEmpty)
                .opacity(amountText.isEmpty ? 0.6 : 1.0)
            }
            .padding(24)
        }
        .presentationDetents([.large])
        .onAppear {
            if let initialAmount = initialAmount {
                amountText = NSDecimalNumber(decimal: initialAmount).stringValue
            }
            if let initialDate = initialDate {
                date = initialDate
            }
            if let initialNote = initialNote {
                note = initialNote
            }
        }
    }
}
