import Foundation
import PDFKit
import SwiftUI

class ExportService {
    static let shared = ExportService()
    
    func generateCSV(for trip: Trip) -> URL? {
        var csvString = "日期,类别,金额,币种,备注\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for bill in trip.bills {
            let date = formatter.string(from: bill.date)
            let category = bill.category.displayName
            let amount = NSDecimalNumber(decimal: bill.amount).stringValue
            let currency = bill.currency ?? trip.currency
            let note = bill.note?.replacingOccurrences(of: ",", with: "，") ?? ""
            
            let line = "\(date),\(category),\(amount),\(currency),\(note)\n"
            csvString.append(line)
        }
        
        let fileName = "\(trip.name)_账单.csv"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            
            do {
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                return fileURL
            } catch {
                print("Failed to write CSV: \(error)")
                return nil
            }
        }
        return nil
    }
    
    func generatePDF(for trip: Trip) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Travel Billing App",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: trip.name
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 595.2 // A4 width
        let pageHeight = 841.8 // A4 height
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        let fileName = "\(trip.name)_账单.pdf"
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = dir.appendingPathComponent(fileName)
        
        do {
            try renderer.writePDF(to: fileURL) { context in
                context.beginPage()
                
                // Draw Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24)
                ]
                let title = "\(trip.name) 账单明细"
                title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
                
                // Draw Summary
                let summaryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14)
                ]
                let totalCNY = NSDecimalNumber(decimal: trip.totalAmount).doubleValue
                let summary = "总开销: ¥\(String(format: "%.2f", totalCNY))"
                summary.draw(at: CGPoint(x: 50, y: 90), withAttributes: summaryAttributes)
                
                // Draw Table Header
                var yOffset = 130.0
                let headerFont = UIFont.boldSystemFont(ofSize: 12)
                
                drawText("日期", x: 50, y: yOffset, font: headerFont)
                drawText("类别", x: 150, y: yOffset, font: headerFont)
                drawText("金额", x: 250, y: yOffset, font: headerFont)
                drawText("备注", x: 350, y: yOffset, font: headerFont)
                
                yOffset += 20
                
                // Draw Rows
                let contentFont = UIFont.systemFont(ofSize: 12)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                for bill in trip.bills {
                    if yOffset > pageHeight - 50 {
                        context.beginPage()
                        yOffset = 50
                    }
                    
                    drawText(dateFormatter.string(from: bill.date), x: 50, y: yOffset, font: contentFont)
                    drawText(bill.category.displayName, x: 150, y: yOffset, font: contentFont)
                    
                    let amountStr = "\(NSDecimalNumber(decimal: bill.amount).stringValue) \(bill.currency ?? trip.currency)"
                    drawText(amountStr, x: 250, y: yOffset, font: contentFont)
                    
                    if let note = bill.note {
                        drawText(note, x: 350, y: yOffset, font: contentFont)
                    }
                    
                    yOffset += 20
                }
            }
            return fileURL
        } catch {
            print("Failed to create PDF: \(error)")
            return nil
        }
    }
    
    private func drawText(_ text: String, x: CGFloat, y: CGFloat, font: UIFont) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
    }
}
