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
        let candidate = try importer.importText("午餐人均68元")
        XCTAssertEqual(candidate.amount, Decimal(68))
        XCTAssertEqual(candidate.sourceType, .text)
    }
    
    // MARK: - InvoiceParser Tests

    func testInvoiceParserExtractsTotal() {
        let parser = InvoiceParser()
        let text = """
        海底捞火锅(望京店)
        2025-12-15
        锅底 ¥68.00
        肥牛卷 ¥48.00
        蔬菜拼盘 ¥32.00
        合计: ¥148.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(148))
        XCTAssertEqual(result.suggestedCategory, .food)
    }

    func testInvoiceParserExtractsLineItems() {
        let parser = InvoiceParser()
        let text = """
        星巴克咖啡
        美式咖啡 28
        拿铁 33元
        合计 61
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.lineItems.count, 2)
        XCTAssertEqual(result.lineItems[0].description, "美式咖啡")
        XCTAssertEqual(result.lineItems[0].amount, Decimal(28))
        XCTAssertEqual(result.lineItems[1].description, "拿铁")
        XCTAssertEqual(result.lineItems[1].amount, Decimal(33))
    }

    func testInvoiceParserExtractsMerchant() {
        let parser = InvoiceParser()
        let text = """
        全聚德烤鸭(前门店)
        2025-03-15
        烤鸭一套 ¥268.00
        合计: ¥268.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.merchantName, "全聚德烤鸭(前门店)")
    }

    func testInvoiceParserExtractsDate() {
        let parser = InvoiceParser()
        let text = """
        某酒店
        2025年03月15日
        房费 ¥580.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertNotNil(result.date)
        let calendar = Calendar.current
        if let date = result.date {
            XCTAssertEqual(calendar.component(.year, from: date), 2025)
            XCTAssertEqual(calendar.component(.month, from: date), 3)
            XCTAssertEqual(calendar.component(.day, from: date), 15)
        }
    }

    func testInvoiceParserSlashDate() {
        let parser = InvoiceParser()
        let text = "消费日期 2025/01/20 金额 ¥100"
        let result = parser.parse(ocrText: text)
        XCTAssertNotNil(result.date)
    }

    func testInvoiceParserNoLineItems() {
        let parser = InvoiceParser()
        let text = "滴滴出行 合计 35元"
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(35))
        XCTAssertEqual(result.suggestedCategory, .transport)
        XCTAssertTrue(result.lineItems.isEmpty)
    }

    func testInvoiceParserVATInvoice() {
        let parser = InvoiceParser()
        let text = """
        增值税电子普通发票
        某某餐饮有限公司
        2025-06-10
        餐饮服务 ¥200.00
        税额 ¥12.00
        价税合计 ¥212.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(string: "212.00"))
    }

    func testInvoiceParserPaymentAmount() {
        let parser = InvoiceParser()
        // E-commerce style: has subtotal and actual payment
        let text = """
        订单详情
        商品金额 ¥150.00
        优惠券 -¥20.00
        实付款: ¥130.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(130))
    }

    func testInvoiceParserTaxiReceipt() {
        let parser = InvoiceParser()
        let text = """
        出租汽车专用发票
        车费 35.00元
        2025-03-20
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(35))
        XCTAssertEqual(result.suggestedCategory, .transport)
    }

    func testInvoiceParserCrossLineTotal() {
        let parser = InvoiceParser()
        // Real OCR often splits keyword and amount across lines
        let text = """
        RECEIPT TOTAL
        USD 1,100.00
        TOTAL TENDERED
        USD 1,100.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(1100))
    }

    func testInvoiceParserCrossLineChinese() {
        let parser = InvoiceParser()
        let text = """
        合计
        ¥258.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(258))
    }

    func testInvoiceParserCurrencySymbolFallback() {
        let parser = InvoiceParser()
        // No keyword, just currency symbol
        let text = "某商店 ¥88.50"
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(string: "88.50"))
    }

    func testInvoiceParserPrefersHigherTier() {
        let parser = InvoiceParser()
        // Both 合计 and 实付 present; 实付 should win (higher tier)
        let text = """
        合计: ¥200.00
        优惠: ¥30.00
        实付: ¥170.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(170))
    }

    func testInvoiceParserCommaThousands() {
        let parser = InvoiceParser()
        let text = "酒店房费 合计 ¥1,280.00"
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(1280))
    }

    func testInvoiceParserLVInvoice() {
        let parser = InvoiceParser()
        let text = """
        CLIENT COPY
        LOUIS VUITTON
        March 10th 2021 13:32
        *Invoice* 87406435
        C3528197/v3800494
        QTY CODE DESCRIPTION ASSOCIATE UNIT PRICE TOTAL PRICE
        1 M80091 FELICIE STRAP GO MNG WEB 880.00 880.00
        PAYMENT SUB-TOTAL USD 880.00
        VISA TAX USD 220.0
        RECEIPT TOTAL USD 1,100.00
        TOTAL TENDERED USD 1,100.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(1100))
        XCTAssertEqual(result.merchantName, "LOUIS VUITTON")
        XCTAssertNotNil(result.date)
        if let date = result.date {
            let cal = Calendar.current
            XCTAssertEqual(cal.component(.year, from: date), 2021)
            XCTAssertEqual(cal.component(.month, from: date), 3)
            XCTAssertEqual(cal.component(.day, from: date), 10)
        }
    }

    func testInvoiceParserLVInvoiceOCRSplit() {
        // Simulate Vision OCR splitting multi-word keywords across lines
        let parser = InvoiceParser()
        let text = """
        CLIENT COPY
        LOUIS VUITTON
        March 10th 2021 13:32
        *Invoice* 87406435
        TOTAL PRICE
        880.00 880.00
        SUB-TOTAL
        USD 880.00
        RECEIPT
        TOTAL
        USD 1,100.00
        TOTAL
        TENDERED
        USD 1,100.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(1100))
    }

    func testInvoiceParserLVInvoiceRealOCR() {
        // Actual Vision OCR output: keywords and amounts in separate columns
        let parser = InvoiceParser()
        let text = """
        CLIENT COPY
        LOUIS VUITTON
        March 10th 2021
        87406435
        13:32
        *Invoice*
        C3528197/v3800494
        OTY CODE
        DESCRIPTION
        ASSOCIATE UNIT PRICE
        TOTAL PRICE
        1 M80091
        PAYMENT
        VISA
        FELICIE STRAP GO MNG
        WEB
        SUB- TOTALUSD
        TAX
        RECEIPT TOTAL
        TOTAL TENDERED
        880.00
        U580.00
        USD
        USD
        880.00
        880.00
        220.0
        1,100.00
        1, 100.00
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(1100))
    }

    func testInvoiceParserEnglishReceipt() {
        let parser = InvoiceParser()
        let text = """
        Walmart Supercenter
        Jan 15, 2025
        Groceries 45.99
        Cleaning supplies 12.50
        Subtotal USD 58.49
        Tax USD 4.68
        Total USD 63.17
        """
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(string: "63.17"))
    }

    func testInvoiceParserCurrencyCodeBeforeAmount() {
        let parser = InvoiceParser()
        let text = "Grand Total EUR 250.00"
        let result = parser.parse(ocrText: text)
        XCTAssertEqual(result.totalAmount, Decimal(250))
    }

    func testInvoiceParserSkipsTotalInLineItems() {
        let parser = InvoiceParser()
        let text = """
        餐厅
        菜品A 50
        菜品B 30
        小计 80
        合计 80
        """
        let result = parser.parse(ocrText: text)
        // Line items should NOT include the 小计 or 合计 rows
        XCTAssertEqual(result.lineItems.count, 2)
        XCTAssertEqual(result.totalAmount, Decimal(80))
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
