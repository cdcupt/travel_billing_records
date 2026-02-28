import SwiftUI
import Vision
import AppKit

struct AddBillView: View {
    let tripId: UUID
    let currency: String
    var onSave: (Bill) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Int = 0
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var category: BillCategory = .food
    @State private var parseError: String?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button("关闭") { dismiss() }
            }
            Picker("", selection: $mode) {
                Text("表单").tag(0)
                Text("图片识别").tag(1)
            }
            .pickerStyle(.segmented)
            
            if mode == 0 {
                Form {
                    Section {
                        TextField("金额 (\(currency))", text: $amountText)
                        Picker("类别", selection: $category) {
                            ForEach(BillCategory.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        DatePicker("日期", selection: $date, displayedComponents: .date)
                        TextField("备注", text: $note)
                    }
                }
                .frame(maxHeight: 320)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Button("选择图片并识别") {
                        recognizeFromImage()
                    }
                    if let parseError {
                        Text(parseError).foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
            }
            
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
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func recognizeFromImage() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic", "tiff"]
        panel.allowsMultipleSelection = false
        panel.begin { result in
            if result == .OK, let url = panel.url, let img = NSImage(contentsOf: url), let cg = self.cgImage(from: img) {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                let handler = VNImageRequestHandler(cgImage: cg, options: [:])
                do {
                    try handler.perform([request])
                    let strings = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
                    let text = strings.joined(separator: "\n")
                    let importer = SimpleTextImporter()
                    let classifier = RuleBasedClassifier()
                    if let candidate = try? importer.importText(text) {
                        self.note = candidate.note
                        if let a = candidate.amount { self.amountText = NSDecimalNumber(decimal: a).stringValue }
                        if let d = candidate.date { self.date = d }
                        self.category = classifier.classify(text: candidate.note)
                        self.parseError = nil
                        self.mode = 0 // Switch back to form
                    } else {
                        self.parseError = "无法解析图片文本"
                    }
                } catch {
                    self.parseError = "识别失败"
                }
            }
        }
    }
    
    private func cgImage(from image: NSImage) -> CGImage? {
        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else { return nil }
        return bitmap.cgImage
    }
}
