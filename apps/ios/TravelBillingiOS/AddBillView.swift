import SwiftUI
import UIKit

struct AddBillView: View {
    let tripId: UUID
    let currency: String
    
    // Make these regular properties, not initial-only
    let initialAmount: Decimal?
    let initialDate: Date?
    let initialNote: String?
    let initialImage: UIImage?
    
    var onSave: (Bill) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var category: BillCategory = .food
    @State private var invoiceImage: UIImage?
    
    init(tripId: UUID, currency: String, initialAmount: Decimal? = nil, initialDate: Date? = nil, initialNote: String? = nil, initialImage: UIImage? = nil, onSave: @escaping (Bill) -> Void) {
        self.tripId = tripId
        self.currency = currency
        self.initialAmount = initialAmount
        self.initialDate = initialDate
        self.initialNote = initialNote
        self.initialImage = initialImage
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
                        // Invoice Image
                        if let image = invoiceImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(Theme.cornerRadius)
                                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
                                .padding(.horizontal)
                        }
                        
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
                    
                    var imagePath: String?
                    if let image = invoiceImage {
                        if let data = image.jpegData(compressionQuality: 0.7) {
                            let filename = UUID().uuidString + ".jpg"
                            // Use standard documents directory URL without resolving symlinks or extra options to avoid FileProvider issues
                            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                            let url = URL(fileURLWithPath: documentsPath).appendingPathComponent(filename)
                            
                            do {
                                try data.write(to: url)
                                imagePath = filename
                                print("Image saved successfully at: \(url.path)")
                            } catch {
                                print("Failed to save image: \(error)")
                            }
                        }
                    }
                    
                    let bill = Bill(
                        tripId: tripId,
                        date: date,
                        amount: amount,
                        currency: currency,
                        category: category,
                        participants: [],
                        note: note,
                        imagePath: imagePath
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
            if let initialImage = initialImage {
                invoiceImage = initialImage
            }
        }
    }
}
