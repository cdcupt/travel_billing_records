import Foundation

struct SampleData {
    static var trip: Trip {
        var t = Trip(name: "Mac 示例旅行", startDate: Date(), endDate: Date(), currency: "CNY")
        let id = t.id
        [
            Bill(tripId: id, date: Date(), amount: 35, currency: "CNY", category: .transport, note: "打车"),
            Bill(tripId: id, date: Date(), amount: 800, currency: "CNY", category: .accommodation, note: "酒店"),
            Bill(tripId: id, date: Date(), amount: 68, currency: "CNY", category: .food, note: "午饭"),
            Bill(tripId: id, date: Date(), amount: 120, currency: "CNY", category: .shopping, note: "纪念品"),
            Bill(tripId: id, date: Date(), amount: 60, currency: "CNY", category: .tickets, note: "门票")
        ].forEach { t.addBill($0) }
        return t
    }
    
    static var trips: [Trip] {
        [trip]
    }
}
