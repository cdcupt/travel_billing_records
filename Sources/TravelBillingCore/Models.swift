import Foundation

public enum BillCategory: String, Codable, CaseIterable, Hashable {
    case transport      // 交通
    case accommodation  // 住宿
    case food           // 餐饮
    case shopping       // 购物
    case entertainment  // 娱乐/景点
    case tickets        // 门票/活动
    case tips           // 小费/服务费
    case misc           // 其他
}

public enum BillSourceType: String, Codable, Hashable {
    case text
    case audio
    case image
}

public struct ParticipantShare: Codable, Hashable {
    public var name: String
    public var amount: Decimal
    
    public init(name: String, amount: Decimal) {
        self.name = name
        self.amount = amount
    }
}

public struct Bill: Codable, Identifiable, Hashable {
    public let id: UUID
    public let tripId: UUID
    public var date: Date
    public var amount: Decimal
    public var currency: String
    public var category: BillCategory
    public var payer: String?
    public var participants: [ParticipantShare]
    public var note: String?
    public var sourceType: BillSourceType
    public var rawSourceURL: URL?
    public var tags: [String]
    
    public init(
        id: UUID = UUID(),
        tripId: UUID,
        date: Date,
        amount: Decimal,
        currency: String,
        category: BillCategory,
        payer: String? = nil,
        participants: [ParticipantShare] = [],
        note: String? = nil,
        sourceType: BillSourceType = .text,
        rawSourceURL: URL? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.tripId = tripId
        self.date = date
        self.amount = amount
        self.currency = currency
        self.category = category
        self.payer = payer
        self.participants = participants
        self.note = note
        self.sourceType = sourceType
        self.rawSourceURL = rawSourceURL
        self.tags = tags
    }
}

public struct Trip: Codable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var startDate: Date
    public var endDate: Date
    public var currency: String
    public var bills: [Bill]
    
    public init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        currency: String = "CNY",
        bills: [Bill] = []
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.currency = currency
        self.bills = bills
    }
    
    public mutating func addBill(_ bill: Bill) {
        bills.append(bill)
    }
    
    public var totalAmount: Decimal {
        bills.reduce(0) { $0 + $1.amount }
    }
}
