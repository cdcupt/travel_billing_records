import SwiftUI

struct TripsListView: View {
    @State var trips: [Trip] = []
    @State private var showAddTrip = false
    @State private var editTrip: Trip?
    @State private var showShareSheet = false
    @State private var itemsToShare: [Any] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if trips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text("还没有旅行账单")
                            .font(Theme.headlineFont())
                            .foregroundColor(Theme.textSecondary)
                        Button {
                            showAddTrip = true
                        } label: {
                            Text("创建第一次旅行")
                                .font(Theme.headlineFont())
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Theme.primary)
                                .cornerRadius(25)
                        }
                    }
                } else {
                    List {
                        ForEach($trips) { $trip in
                            ZStack {
                                NavigationLink {
                                    TripDetailView(trip: trip) { updated in
                                        if let idx = trips.firstIndex(where: { $0.id == updated.id }) {
                                            trips[idx] = updated
                                            Persistence.shared.saveTrips(trips)
                                        }
                                    }
                                } label: {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                TripCardView(trip: trip)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    if let url = ExportService().generateCSV(for: trip) {
                                        itemsToShare = [url]
                                        showShareSheet = true
                                    }
                                } label: {
                                    Label("导出 CSV", systemImage: "doc.text")
                                }
                                .tint(.green)
                                
                                Button {
                                    if let url = ExportService().generatePDF(for: trip) {
                                        itemsToShare = [url]
                                        showShareSheet = true
                                    }
                                } label: {
                                    Label("导出 PDF", systemImage: "doc.richtext")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("删除", role: .destructive) {
                                    if let idx = trips.firstIndex(where: { $0.id == trip.id }) {
                                        trips.remove(at: idx)
                                        Persistence.shared.saveTrips(trips)
                                    }
                                }
                                Button("编辑") {
                                    editTrip = trip
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("旅行账单")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTrip = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .onAppear {
                trips = Persistence.shared.loadTrips()
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
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: itemsToShare)
            }
        }
    }
}

struct TripCardView: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(trip.name)
                    .font(Theme.titleFont().weight(.bold))
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text(trip.startDate, style: .date)
                        .font(Theme.subheadlineFont())
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("总开销")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                
                let totalCNY = NSDecimalNumber(decimal: trip.totalAmount).doubleValue
                Text("¥\(totalCNY, specifier: "%.2f")")
                    .font(Theme.headlineFont())
                    .foregroundColor(Theme.primary)
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
