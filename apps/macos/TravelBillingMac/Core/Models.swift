import Foundation

public enum BillCategory: String, Codable, CaseIterable, Hashable {
    case transport
    case accommodation
    case food
    case shopping
    case entertainment
    case tickets
    case tips
    case misc
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
    public var currency: String?
    public var category: BillCategory
    public var payer: String?
    public var participants: [ParticipantShare]
    public var note: String?
    public var sourceType: BillSourceType
    public var rawSourceURL: URL?
    public var imagePath: String?
    public var tags: [String]
    
    public init(
        id: UUID = UUID(),
        tripId: UUID,
        date: Date,
        amount: Decimal,
        currency: String? = nil,
        category: BillCategory,
        payer: String? = nil,
        participants: [ParticipantShare] = [],
        note: String? = nil,
        sourceType: BillSourceType = .text,
        rawSourceURL: URL? = nil,
        imagePath: String? = nil,
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
        self.imagePath = imagePath
        self.tags = tags
    }
}

public struct Trip: Codable, Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var startDate: Date
    public var endDate: Date
    public var currency: String
    public var exchangeRate: Double // 1 外币 = x CNY
    public var bills: [Bill]
    
    public init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        currency: String = "CNY",
        exchangeRate: Double = 1.0,
        bills: [Bill] = []
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.currency = currency
        self.exchangeRate = exchangeRate
        self.bills = bills
    }
    
    public mutating func addBill(_ bill: Bill) {
        bills.append(bill)
    }
    
    public var totalAmount: Decimal {
        bills.reduce(0) { $0 + $1.amount * Decimal(exchangeRate) }
    }
}
