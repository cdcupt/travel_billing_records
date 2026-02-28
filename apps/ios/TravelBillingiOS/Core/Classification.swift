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
            "早餐","午餐","晚餐","夜宵","餐饮","饭","餐厅","点餐","外卖","咖啡","奶茶","饮料","酒吧","小吃","甜品","餐费"
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
        var candidates: [(value: Decimal, score: Int)] = []
        
        // Helper to process matches
        func processMatches(pattern: String, baseScore: Int) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                guard match.numberOfRanges > 1,
                      let r = Range(match.range(at: 1), in: text) else { continue }
                
                let numStr = String(text[r]).replacingOccurrences(of: ",", with: "")
                if let decimal = Decimal(string: numStr) {
                    var score = baseScore
                    let doubleVal = NSDecimalNumber(decimal: decimal).doubleValue
                    
                    // Penalty for likely years (e.g. 2020-2030) if it looks like an integer
                    // But if it was matched with a currency symbol (baseScore >= 80), we trust it more.
                    if baseScore < 50 && doubleVal >= 1990 && doubleVal <= 2035 && doubleVal.truncatingRemainder(dividingBy: 1) == 0 {
                        score -= 60
                    }
                    
                    // Penalty for very small integers (quantities like 1, 2) in loose mode
                    if baseScore < 50 && doubleVal < 10 && doubleVal.truncatingRemainder(dividingBy: 1) == 0 {
                        score -= 30
                    }
                    
                    // Bonus for 2 decimal places (cents)
                    if numStr.contains(".") {
                        let components = numStr.split(separator: ".")
                        if components.count == 2 && components[1].count == 2 {
                            score += 10
                        }
                    }
                    
                    candidates.append((decimal, score))
                }
            }
        }
        
        // Priority 1: Strong prefix (Currency symbol or Keyword)
        // Matches: ¥2880.00, Total: 1,000.00, ￥200
        // Note: Regex alternation order matters or strictness matters. We force at least one comma group for the first part to avoid partial matching of plain numbers.
        let strongPattern = #"(?:Total|Amount|合计|金额|实付|应付|¥|￥|\$|€|£)\s*:?\s*(\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?)"#
        processMatches(pattern: strongPattern, baseScore: 100)
        
        // Priority 2: Strong suffix
        // Matches: 100元, 100 CNY
        let suffixPattern = #"(\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?)\s*(?:元|rmb|cny|usd|eur|krw|thb)"#
        processMatches(pattern: suffixPattern, baseScore: 80)
        
        // Priority 3: Loose numbers (Fallback)
        // Matches: 2880.00, 1000
        let loosePattern = #"(\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?)"#
        processMatches(pattern: loosePattern, baseScore: 20)
        
        // Select best candidate
        // Sort by Score DESC, then Value DESC (preferring larger amounts like Total over unit prices)
        let best = candidates.sorted {
            if $0.score != $1.score {
                return $0.score > $1.score
            }
            return $0.value > $1.value
        }.first
        
        return best?.value
    }
    
    private static func match(pattern: String, in text: String) -> Decimal? {
        // Deprecated, keeping for compatibility if needed, or remove.
        // For now, extractAmount is self-contained.
        return nil
    }
    
    private static func extractDate(from text: String) -> Date? {
        return Date()
    }
}
