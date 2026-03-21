import Foundation

public protocol BillClassifier {
    func classify(text: String) -> BillCategory
}

public final class RuleBasedClassifier: BillClassifier {
    private struct KeywordMap {
        let category: BillCategory
        let keywords: [String]
    }
    
    private let maps: [KeywordMap] = [
        .init(category: .transport, keywords: [
            "打车","出租","滴滴","的士","地铁","公交","巴士","动车","高铁","火车","租车","加油","油费","停车","过路费","航班","飞机","机票","船票","快车","顺风车","网约车"
        ]),
        .init(category: .accommodation, keywords: [
            "酒店","旅馆","青旅","民宿","宾馆","住宿","房费","订房","入住","退房","airbnb","客栈"
        ]),
        .init(category: .food, keywords: [
            "早餐","午餐","晚餐","夜宵","餐饮","饭","餐厅","点餐","外卖","咖啡","奶茶","饮料","酒吧","小吃","甜品","餐费","火锅","烤鸭","烧烤"
        ]),
        .init(category: .shopping, keywords: [
            "购物","商场","超市","便利店","纪念品","礼物","手信","买","购买","免税店","特产"
        ]),
        .init(category: .entertainment, keywords: [
            "游玩","娱乐","景点","观光","体验","冲浪","潜水","滑雪","演出","展览","按摩","温泉","瑜伽","租赁设备"
        ]),
        .init(category: .tickets, keywords: [
            "门票","入场","预约","票务","通票","套票","打卡"
        ]),
        .init(category: .tips, keywords: [
            "小费","服务费","附加费","税费","手续费"
        ])
    ]
    
    public init() {}
    
    public func classify(text: String) -> BillCategory {
        let normalized = text.lowercased()
        for map in maps {
            if map.keywords.contains(where: { normalized.contains($0.lowercased()) }) {
                return map.category
            }
        }
        return .misc
    }
}

public enum ImportError: Error {
    case invalidInput
}

public struct ImportedBillCandidate {
    public let note: String
    public let amount: Decimal?
    public let date: Date?
    public let sourceType: BillSourceType
    
    public init(note: String, amount: Decimal?, date: Date?, sourceType: BillSourceType) {
        self.note = note
        self.amount = amount
        self.date = date
        self.sourceType = sourceType
    }
}

public protocol TextBillImporter {
    func importText(_ text: String) throws -> ImportedBillCandidate
}

// MARK: - Invoice Parser

public struct InvoiceLineItem {
    public let description: String
    public let amount: Decimal

    public init(description: String, amount: Decimal) {
        self.description = description
        self.amount = amount
    }
}

public struct InvoiceResult {
    public let merchantName: String?
    public let date: Date?
    public let lineItems: [InvoiceLineItem]
    public let totalAmount: Decimal?
    public let suggestedCategory: BillCategory
    public let rawText: String

    public init(merchantName: String?, date: Date?, lineItems: [InvoiceLineItem],
                totalAmount: Decimal?, suggestedCategory: BillCategory, rawText: String) {
        self.merchantName = merchantName
        self.date = date
        self.lineItems = lineItems
        self.totalAmount = totalAmount
        self.suggestedCategory = suggestedCategory
        self.rawText = rawText
    }
}

public final class InvoiceParser {
    private let classifier = RuleBasedClassifier()

    public init() {}

    public func parse(ocrText: String) -> InvoiceResult {
        let lines = ocrText.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        let merchantName = extractMerchant(lines: lines)
        let date = extractDate(from: ocrText)
        let lineItems = extractLineItems(lines: lines)
        let totalAmount = extractTotal(from: ocrText) ?? lineItems.reduce(nil) { (sum: Decimal?, item) -> Decimal? in
            (sum ?? 0) + item.amount
        }
        let category = classifier.classify(text: ocrText)

        return InvoiceResult(
            merchantName: merchantName,
            date: date,
            lineItems: lineItems,
            totalAmount: totalAmount,
            suggestedCategory: category,
            rawText: ocrText
        )
    }

    // MARK: - Merchant extraction

    private func extractMerchant(lines: [String]) -> String? {
        let skipKeywords = ["发票", "收据", "小票", "电子发票", "增值税", "机打发票", "税务",
                            "client copy", "invoice", "receipt", "qty", "description",
                            "associate", "payment", "visa", "mastercard", "return policy"]
        for line in lines.prefix(8) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.count < 2 { continue }
            // Skip dates
            if trimmed.range(of: #"^\d{4}[-/]\d{1,2}[-/]\d{1,2}"#, options: .regularExpression) != nil { continue }
            if trimmed.range(of: #"^(?:January|February|March|April|May|June|July|August|September|October|November|December)\s"#, options: [.regularExpression, .caseInsensitive]) != nil { continue }
            // Skip pure numbers / currency
            if trimmed.range(of: #"^[\d.,\s¥￥$€£]+$"#, options: .regularExpression) != nil { continue }
            // Skip header/boilerplate lines
            if skipKeywords.contains(where: { trimmed.lowercased().contains($0.lowercased()) }) { continue }
            // Skip lines that are just codes like "C3528197/v3800494" or "*Invoice* 87406435"
            if trimmed.range(of: #"^[A-Z\d/\-*\s]{3,}$"#, options: .regularExpression) != nil && !trimmed.contains(" ") { continue }
            return trimmed
        }
        return nil
    }

    // MARK: - Date extraction

    private static let dateFormatters: [DateFormatter] = {
        let formats = ["yyyy-MM-dd", "yyyy/MM/dd", "yyyy年MM月dd日", "yyyy.MM.dd",
                       "MM-dd-yyyy", "MM/dd/yyyy", "dd/MM/yyyy",
                       "MMMM d yyyy", "MMMM dd yyyy", "MMM d yyyy", "MMM dd yyyy",
                       "MMMM d, yyyy", "MMM d, yyyy", "dd MMMM yyyy", "d MMMM yyyy"]
        return formats.flatMap { fmt -> [DateFormatter] in
            let df = DateFormatter()
            df.dateFormat = fmt
            df.locale = Locale(identifier: "en_US")
            let dfCN = DateFormatter()
            dfCN.dateFormat = fmt
            dfCN.locale = Locale(identifier: "zh_CN")
            return [df, dfCN]
        }
    }()

    func extractDate(from text: String) -> Date? {
        let patterns = [
            // Chinese: 2025-03-15, 2025/03/15, 2025年3月15日
            #"\d{4}[-/年.]\d{1,2}[-/月.]\d{1,2}日?"#,
            // US: 03/15/2025, 03-15-2025
            #"\d{1,2}[-/]\d{1,2}[-/]\d{4}"#,
            // English: March 10th 2021, Mar 10, 2021, January 5 2025
            #"(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4}"#,
            // English reversed: 10 March 2021
            #"\d{1,2}\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let r = Range(match.range, in: text) {
                var dateStr = String(text[r])
                // Remove ordinal suffixes (1st, 2nd, 3rd, 10th)
                dateStr = dateStr.replacingOccurrences(of: #"(\d)(st|nd|rd|th)"#, with: "$1", options: .regularExpression)
                // Try all formatters
                for formatter in Self.dateFormatters {
                    if let date = formatter.date(from: dateStr) { return date }
                }
                // Try cleaning up Chinese date markers
                let cleaned = dateStr.replacingOccurrences(of: "年", with: "-")
                    .replacingOccurrences(of: "月", with: "-")
                    .replacingOccurrences(of: "日", with: "")
                for formatter in Self.dateFormatters {
                    if let date = formatter.date(from: cleaned) { return date }
                }
            }
        }
        return nil
    }

    // MARK: - Line items extraction

    private func extractLineItems(lines: [String]) -> [InvoiceLineItem] {
        var items: [InvoiceLineItem] = []
        // Pattern: description text followed by optional currency and amount
        // Handles: "红烧牛肉面 ¥38.00", "咖啡 28元", "FELICIE STRAP GO MNG  880.00", "Item USD 50.00"
        let lineItemPattern = #"^(.+?)\s+(?:[¥￥$€£]\s*|(?:USD|EUR|GBP|CNY|JPY)\s+)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\s*(?:元|rmb|cny|usd|eur|gbp)?$"#
        guard let regex = try? NSRegularExpression(pattern: lineItemPattern, options: .caseInsensitive) else { return items }

        // Skip total/subtotal/header lines
        let skipKeywords = ["合计", "总计", "小计", "应付", "实付", "找零", "实收",
                            "total", "subtotal", "sub-total", "tendered", "payment",
                            "tax", "qty", "code", "description", "unit price", "total price"]

        for line in lines {
            let lower = line.lowercased()
            if skipKeywords.contains(where: { lower.contains($0) }) { continue }
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, range: range),
               match.numberOfRanges >= 3,
               let descRange = Range(match.range(at: 1), in: line),
               let amtRange = Range(match.range(at: 2), in: line) {
                let desc = String(line[descRange]).trimmingCharacters(in: .whitespaces)
                let amtStr = String(line[amtRange]).replacingOccurrences(of: ",", with: "")
                if let amount = Decimal(string: amtStr), !desc.isEmpty, amount > 0 {
                    items.append(InvoiceLineItem(description: desc, amount: amount))
                }
            }
        }
        return items
    }

    // MARK: - Total extraction (priority-scored)

    private struct AmountCandidate {
        let value: Decimal
        let score: Int
    }

    // Amount pattern: handles currency symbol OR currency code before/after number
    // e.g. "¥1,100.00", "USD 1,100.00", "1,100.00 USD", "880.00元"
    private static let amountPattern = #"(?:[¥￥$€£]\s*|(?:USD|EUR|GBP|CNY|JPY|KRW|THB|RMB)\s+)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)(?:\s*(?:元|rmb|cny|usd|eur|gbp|jpy|krw|thb))?"#

    private func extractTotal(from text: String) -> Decimal? {
        var candidates: [AmountCandidate] = []

        // Tier 1 (score 200): Receipt/invoice final total
        let tier1Keywords = ["价税合计", "小写", "大写",
                             "receipt total", "total tendered", "grand total", "net total"]
        // Tier 2 (score 150): Payment amount
        let tier2Keywords = ["实付款", "实付金额", "应付金额", "实收金额", "订单金额", "刷卡金额", "实付", "应付",
                             "amount paid", "amount due", "balance due", "payment"]
        // Tier 3 (score 120): Generic total
        let tier3Keywords = ["金额合计", "合计金额", "合计", "总计", "总额",
                             "sub-total", "subtotal", "total price", "total"]
        // Tier 4 (score 100): Contextual
        let tier4Keywords = ["金额", "车费", "票价", "房费", "费用", "消费",
                             "amount", "price", "fare", "charge"]

        let tiers: [(keywords: [String], score: Int)] = [
            (tier1Keywords, 200),
            (tier2Keywords, 150),
            (tier3Keywords, 120),
            (tier4Keywords, 100),
        ]

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        // Amount-only pattern for window scanning
        let amountOnly = #"(\d{1,3}(?:,\d{3})*\.\d+|\d+\.\d+)"#
        let amountOnlyRegex = try? NSRegularExpression(pattern: amountOnly, options: [])

        for (keywords, baseScore) in tiers {
            for keyword in keywords {
                let escaped = NSRegularExpression.escapedPattern(for: keyword)
                    .replacingOccurrences(of: " ", with: #"[\s\n]+"#)
                    .replacingOccurrences(of: "\\-", with: #"[\s\n]*\-[\s\n]*"#)
                // Allow newlines/whitespace between keyword and amount (OCR often splits across lines)
                let pattern = escaped + #"[\s\n]*[:：]?[\s\n]*"# + Self.amountPattern
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { continue }
                for match in regex.matches(in: text, range: fullRange) {
                    if match.numberOfRanges >= 2, let r = Range(match.range(at: 1), in: text) {
                        let str = String(text[r]).replacingOccurrences(of: ",", with: "")
                        if let val = Decimal(string: str), val > 0 {
                            var score = baseScore
                            if str.contains("."), let dotIdx = str.firstIndex(of: "."),
                               str[str.index(after: dotIdx)...].count == 2 {
                                score += 10
                            }
                            candidates.append(AmountCandidate(value: val, score: score))
                        }
                    }
                }

                // Tier 1 window scan: OCR may separate keywords from amounts across columns.
                // Find the keyword position and scan all amounts within 400 chars; use the largest.
                if baseScore >= 200, let amountOnlyRegex {
                    let kwPattern = escaped
                    if let kwRegex = try? NSRegularExpression(pattern: kwPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
                       let kwMatch = kwRegex.firstMatch(in: text, range: fullRange) {
                        let kwEnd = kwMatch.range.location + kwMatch.range.length
                        let scanLen = min(400, nsText.length - kwEnd)
                        if scanLen > 0 {
                            let scanRange = NSRange(location: kwEnd, length: scanLen)
                            var maxVal: Decimal = 0
                            var maxStr = ""
                            for m in amountOnlyRegex.matches(in: text, range: scanRange) {
                                if let r = Range(m.range(at: 1), in: text) {
                                    let s = String(text[r]).replacingOccurrences(of: ",", with: "")
                                    if let v = Decimal(string: s), v > maxVal {
                                        maxVal = v; maxStr = s
                                    }
                                }
                            }
                            if maxVal > 0 {
                                var score = baseScore
                                if maxStr.contains("."), let dotIdx = maxStr.firstIndex(of: "."),
                                   maxStr[maxStr.index(after: dotIdx)...].count == 2 {
                                    score += 10
                                }
                                candidates.append(AmountCandidate(value: maxVal, score: score))
                            }
                        }
                    }
                }
            }
        }

        // Tier 5: Currency-symbol-prefixed OR currency-code-prefixed amounts
        let currencyPattern = #"(?:[¥￥$€£]|(?:USD|EUR|GBP|CNY|JPY)\s)\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)"#
        if let regex = try? NSRegularExpression(pattern: currencyPattern, options: .caseInsensitive) {
            for match in regex.matches(in: text, range: fullRange) {
                if match.numberOfRanges >= 2, let r = Range(match.range(at: 1), in: text) {
                    let str = String(text[r]).replacingOccurrences(of: ",", with: "")
                    if let val = Decimal(string: str), val > 0 {
                        candidates.append(AmountCandidate(value: val, score: 60))
                    }
                }
            }
        }

        // Tier 6: Number with currency suffix
        let suffixPattern = #"(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*(?:元|rmb|cny|usd|eur|gbp|jpy|krw|thb)"#
        if let regex = try? NSRegularExpression(pattern: suffixPattern, options: .caseInsensitive) {
            for match in regex.matches(in: text, range: fullRange) {
                if match.numberOfRanges >= 2, let r = Range(match.range(at: 1), in: text) {
                    let str = String(text[r]).replacingOccurrences(of: ",", with: "")
                    if let val = Decimal(string: str), val > 0 {
                        let dv = NSDecimalNumber(decimal: val).doubleValue
                        if dv >= 1990 && dv <= 2035 && dv.truncatingRemainder(dividingBy: 1) == 0 { continue }
                        candidates.append(AmountCandidate(value: val, score: 40))
                    }
                }
            }
        }

        return candidates
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.value > $1.value }
            .first?.value
    }
}

public final class SimpleTextImporter: TextBillImporter {
    public init() {}
    
    public func importText(_ text: String) throws -> ImportedBillCandidate {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ImportError.invalidInput }
        
        let amount = Self.extractAmount(from: trimmed)
        let date = Self.extractDate(from: trimmed)
        return ImportedBillCandidate(note: trimmed, amount: amount, date: date, sourceType: .text)
    }
    
    private static func extractAmount(from text: String) -> Decimal? {
        // very naive: find numbers like 123 or 123.45 optionally followed by 元
        let pattern = #"(\d+(?:\.\d+)?)\s*(?:元|rmb|cny)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let numRange = Range(match.range(at: 1), in: text) {
            return Decimal(string: String(text[numRange]))
        }
        return nil
    }
    
    private static func extractDate(from text: String) -> Date? {
        // naive: try today. Real impl would parse "2025-10-31" etc.
        return Date()
    }
}
