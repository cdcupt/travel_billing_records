import XCTest
@testable import TravelBillingCore

final class ClassificationTests: XCTestCase {
    func testRuleBasedClassifier() {
        let cls = RuleBasedClassifier()
        XCTAssertEqual(cls.classify(text: "滴滴打车 35元"), .transport)
        XCTAssertEqual(cls.classify(text: "酒店两晚 800"), .accommodation)
        XCTAssertEqual(cls.classify(text: "午饭 68 元"), .food)
        XCTAssertEqual(cls.classify(text: "买纪念品 120"), .shopping)
        XCTAssertEqual(cls.classify(text: "温泉体验 260"), .entertainment)
        XCTAssertEqual(cls.classify(text: "故宫门票 60"), .tickets)
        XCTAssertEqual(cls.classify(text: "服务费10"), .tips)
        XCTAssertEqual(cls.classify(text: "未知支出 88"), .misc)
    }
    
    func testTextImporterExtractsAmount() throws {
        let importer = SimpleTextImporter()
        let candidate = try importer.importText("午餐人均68元，共两人，合计136元")
        XCTAssertEqual(candidate.amount, Decimal(136))
        XCTAssertEqual(candidate.sourceType, .text)
    }
    
    func testStatisticsSummary() {
        var trip = Trip(name: "三亚旅行", startDate: Date(), endDate: Date())
        let tId = trip.id
        let bills: [Bill] = [
            Bill(tripId: tId, date: Date(), amount: 35, currency: "CNY", category: .transport, note: "打车"),
            Bill(tripId: tId, date: Date(), amount: 800, currency: "CNY", category: .accommodation, note: "酒店"),
            Bill(tripId: tId, date: Date(), amount: 68, currency: "CNY", category: .food, note: "午饭"),
            Bill(tripId: tId, date: Date(), amount: 120, currency: "CNY", category: .shopping, note: "纪念品")
        ]
        bills.forEach { trip.addBill($0) }
        let catSummary = Statistics.summarizeByCategory(for: trip)
        XCTAssertEqual(catSummary.count, 4)
        XCTAssertEqual(catSummary.first?.category, .accommodation)
        
        let daily = Statistics.summarizeDaily(for: trip)
        XCTAssertEqual(daily.count, 1)
        XCTAssertEqual(daily.first?.total, 35 + 800 + 68 + 120)
    }
}
