import SwiftUI

@main
struct TravelBillingMacApp: App {
    var body: some Scene {
        WindowGroup {
            TripsListView(trips: SampleData.trips)
        }
    }
}
