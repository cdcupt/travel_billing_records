import SwiftUI

struct TripsListView: View {
    @State var trips: [Trip] = []
    @State private var showAddTrip = false
    @State private var editTrip: Trip?
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($trips) { $trip in
                    NavigationLink {
                        TripDetailView(trip: trip) { updated in
                            if let idx = trips.firstIndex(where: { $0.id == updated.id }) {
                                trips[idx] = updated
                                Persistence.shared.saveTrips(trips)
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.name).font(.headline)
                            let totalCNY = NSDecimalNumber(decimal: trip.totalAmount).doubleValue
                            Text("总开销 ¥\(totalCNY, specifier: "%.2f") CNY")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("编辑") {
                            editTrip = trip
                        }
                        Button("删除") {
                            if let idx = trips.firstIndex(where: { $0.id == trip.id }) {
                                trips.remove(at: idx)
                                Persistence.shared.saveTrips(trips)
                            }
                        }
                    }
                }
            }
            .navigationTitle("旅行项目（Mac）")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .onAppear {
            trips = Persistence.shared.loadTrips()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAddTrip) {
            NewTripView { newTrip in
                trips.append(newTrip)
                Persistence.shared.saveTrips(trips)
            }
        }
        .sheet(item: $editTrip) { editing in
            EditTripView(trip: editing) { updated in
                if let idx = trips.firstIndex(where: { $0.id == updated.id }) {
                    trips[idx] = updated
                    Persistence.shared.saveTrips(trips)
                }
                editTrip = nil
            }
        }
    }
}
