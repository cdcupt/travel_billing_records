import Foundation
import CoreData

final class Persistence {
    static let shared = Persistence()
    let container: NSPersistentContainer
    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "TravelBilling", managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        // Set the URL explicitly to ensure we are using the default location
        if let url = container.persistentStoreDescriptions.first?.url {
            description.url = url
        }
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { desc, error in
            if let error = error {
                print("Core Data failed to load: \(error)")
            } else {
                print("Core Data loaded: \(desc)")
            }
        }
    }
    
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        let trip = NSEntityDescription()
        trip.name = "TripEntity"
        trip.managedObjectClassName = NSManagedObject.self.description()
        
        let bill = NSEntityDescription()
        bill.name = "BillEntity"
        bill.managedObjectClassName = NSManagedObject.self.description()
        
        let t_id = NSAttributeDescription()
        t_id.name = "id"
        t_id.attributeType = .UUIDAttributeType
        t_id.isOptional = false
        let t_name = NSAttributeDescription()
        t_name.name = "name"
        t_name.attributeType = .stringAttributeType
        let t_start = NSAttributeDescription()
        t_start.name = "startDate"
        t_start.attributeType = .dateAttributeType
        let t_end = NSAttributeDescription()
        t_end.name = "endDate"
        t_end.attributeType = .dateAttributeType
        let t_currency = NSAttributeDescription()
        t_currency.name = "currency"
        t_currency.attributeType = .stringAttributeType
        let t_rate = NSAttributeDescription()
        t_rate.name = "exchangeRate"
        t_rate.attributeType = .doubleAttributeType
        
        trip.properties = [t_id, t_name, t_start, t_end, t_currency, t_rate]
        
        let b_id = NSAttributeDescription()
        b_id.name = "id"
        b_id.attributeType = .UUIDAttributeType
        b_id.isOptional = false
        let b_date = NSAttributeDescription()
        b_date.name = "date"
        b_date.attributeType = .dateAttributeType
        let b_amount = NSAttributeDescription()
        b_amount.name = "amount"
        b_amount.attributeType = .doubleAttributeType
        let b_currency = NSAttributeDescription()
        b_currency.name = "currency"
        b_currency.attributeType = .stringAttributeType
        let b_category = NSAttributeDescription()
        b_category.name = "category"
        b_category.attributeType = .stringAttributeType
        let b_payer = NSAttributeDescription()
        b_payer.name = "payer"
        b_payer.attributeType = .stringAttributeType
        b_payer.isOptional = true
        let b_note = NSAttributeDescription()
        b_note.name = "note"
        b_note.attributeType = .stringAttributeType
        b_note.isOptional = true
        let b_participants = NSAttributeDescription()
        b_participants.name = "participants"
        b_participants.attributeType = .binaryDataAttributeType
        b_participants.isOptional = true
        let b_tags = NSAttributeDescription()
        b_tags.name = "tags"
        b_tags.attributeType = .binaryDataAttributeType
        b_tags.isOptional = true
        let b_sourceType = NSAttributeDescription()
        b_sourceType.name = "sourceType"
        b_sourceType.attributeType = .stringAttributeType
        let b_imagePath = NSAttributeDescription()
        b_imagePath.name = "imagePath"
        b_imagePath.attributeType = .stringAttributeType
        b_imagePath.isOptional = true
        
        let r_trip = NSRelationshipDescription()
        r_trip.name = "trip"
        r_trip.destinationEntity = trip
        r_trip.minCount = 1
        r_trip.maxCount = 1
        r_trip.deleteRule = .nullifyDeleteRule
        
        let r_bills = NSRelationshipDescription()
        r_bills.name = "bills"
        r_bills.destinationEntity = bill
        r_bills.minCount = 0
        r_bills.maxCount = 0
        r_bills.deleteRule = .cascadeDeleteRule
        
        r_trip.inverseRelationship = r_bills
        r_bills.inverseRelationship = r_trip
        
        trip.properties.append(r_bills)
        bill.properties = [b_id, b_date, b_amount, b_currency, b_category, b_payer, b_note, b_participants, b_tags, b_sourceType, b_imagePath, r_trip]
        
        model.entities = [trip, bill]
        return model
    }
    
    func loadTrips() -> [Trip] {
        let ctx = container.viewContext
        let req = NSFetchRequest<NSManagedObject>(entityName: "TripEntity")
        let tripsMO = (try? ctx.fetch(req)) ?? []
        return tripsMO.map { mo in
            let id = mo.value(forKey: "id") as? UUID ?? UUID()
            let name = mo.value(forKey: "name") as? String ?? ""
            let start = mo.value(forKey: "startDate") as? Date ?? Date()
            let end = mo.value(forKey: "endDate") as? Date ?? Date()
            let currency = mo.value(forKey: "currency") as? String ?? "CNY"
            let rate = mo.value(forKey: "exchangeRate") as? Double ?? 1.0
            var trip = Trip(id: id, name: name, startDate: start, endDate: end, currency: currency, exchangeRate: rate)
            if let bills = mo.value(forKey: "bills") as? Set<NSManagedObject> {
                for b in bills {
                    let bid = b.value(forKey: "id") as? UUID ?? UUID()
                    let date = b.value(forKey: "date") as? Date ?? Date()
                    let amount = Decimal(Double(b.value(forKey: "amount") as? Double ?? 0))
                    let bc = b.value(forKey: "currency") as? String ?? "CNY"
                    let catRaw = b.value(forKey: "category") as? String ?? BillCategory.misc.rawValue
                    let cat = BillCategory(rawValue: catRaw) ?? .misc
                    let payer = b.value(forKey: "payer") as? String
                    let note = b.value(forKey: "note") as? String
                    let sourceTypeRaw = b.value(forKey: "sourceType") as? String ?? BillSourceType.text.rawValue
                    let sourceType = BillSourceType(rawValue: sourceTypeRaw) ?? .text
                    
                    // Force refresh object to get latest property values
                    ctx.refresh(b, mergeChanges: true)
                    let imagePath = b.value(forKey: "imagePath") as? String
                    
                    var participants: [ParticipantShare] = []
                    if let pdata = b.value(forKey: "participants") as? Data,
                       let arr = try? JSONDecoder().decode([ParticipantShare].self, from: pdata) {
                        participants = arr
                    }
                    var tags: [String] = []
                    if let tdata = b.value(forKey: "tags") as? Data,
                       let arr = try? JSONDecoder().decode([String].self, from: tdata) {
                        tags = arr
                    }
                    let bill = Bill(id: bid, tripId: id, date: date, amount: amount, currency: bc, category: cat, payer: payer, participants: participants, note: note, sourceType: sourceType, rawSourceURL: nil, imagePath: imagePath, tags: tags)
                    trip.addBill(bill)
                }
            }
            // Sort bills by date descending by default
            trip.bills.sort { $0.date > $1.date }
            return trip
        }
    }
    
    func saveTrips(_ trips: [Trip]) {
        let ctx = container.viewContext
        // Optimistic locking: Merge changes instead of full wipe
        // But for simplicity in this demo app, we'll use a smarter update approach
        
        let req = NSFetchRequest<NSManagedObject>(entityName: "TripEntity")
        let existing = (try? ctx.fetch(req)) ?? []
        
        // Map existing trips by ID for updates
        var existingTripsMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.value(forKey: "id") as? UUID ?? UUID(), $0) })
        
        for trip in trips {
            let tmo: NSManagedObject
            if let existing = existingTripsMap[trip.id] {
                tmo = existing
                existingTripsMap.removeValue(forKey: trip.id)
            } else {
                tmo = NSEntityDescription.insertNewObject(forEntityName: "TripEntity", into: ctx)
                tmo.setValue(trip.id, forKey: "id")
            }
            
            tmo.setValue(trip.name, forKey: "name")
            tmo.setValue(trip.startDate, forKey: "startDate")
            tmo.setValue(trip.endDate, forKey: "endDate")
            tmo.setValue(trip.currency, forKey: "currency")
            tmo.setValue(trip.exchangeRate, forKey: "exchangeRate")
            
            // Handle bills
            let billsReq = NSFetchRequest<NSManagedObject>(entityName: "BillEntity")
            billsReq.predicate = NSPredicate(format: "trip == %@", tmo)
            let existingBills = (try? ctx.fetch(billsReq)) ?? []
            var existingBillsMap = Dictionary(uniqueKeysWithValues: existingBills.map { ($0.value(forKey: "id") as? UUID ?? UUID(), $0) })
            
            var billsSet: Set<NSManagedObject> = []
            for bill in trip.bills {
                let bmo: NSManagedObject
                if let existing = existingBillsMap[bill.id] {
                    bmo = existing
                    existingBillsMap.removeValue(forKey: bill.id)
                } else {
                    bmo = NSEntityDescription.insertNewObject(forEntityName: "BillEntity", into: ctx)
                    bmo.setValue(bill.id, forKey: "id")
                }
                
                bmo.setValue(bill.date, forKey: "date")
                bmo.setValue(NSDecimalNumber(decimal: bill.amount).doubleValue, forKey: "amount")
                bmo.setValue(bill.currency ?? "CNY", forKey: "currency")
                bmo.setValue(bill.category.rawValue, forKey: "category")
                bmo.setValue(bill.payer, forKey: "payer")
                bmo.setValue(bill.note, forKey: "note")
                bmo.setValue(bill.sourceType.rawValue, forKey: "sourceType")
                bmo.setValue(bill.imagePath, forKey: "imagePath")
                
                if let pdata = try? JSONEncoder().encode(bill.participants) {
                    bmo.setValue(pdata, forKey: "participants")
                }
                if let tdata = try? JSONEncoder().encode(bill.tags) {
                    bmo.setValue(tdata, forKey: "tags")
                }
                bmo.setValue(tmo, forKey: "trip")
                billsSet.insert(bmo)
            }
            
            // Delete removed bills
            for bmo in existingBillsMap.values {
                ctx.delete(bmo)
            }
            
            tmo.setValue(billsSet, forKey: "bills")
        }
        
        // Delete removed trips
        for tmo in existingTripsMap.values {
            ctx.delete(tmo)
        }
        
        do {
            try ctx.save()
            print("Successfully saved trips to Core Data")
        } catch {
            print("Failed to save trips: \(error)")
        }
    }
}
