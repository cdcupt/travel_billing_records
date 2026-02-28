import SwiftUI

@main
struct TravelBillingiOSApp: App {
    var body: some Scene {
        WindowGroup {
            TripsListView(trips: SampleData.trips)
                .tint(Theme.accent)
        }
    }
}
