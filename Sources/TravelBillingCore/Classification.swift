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
