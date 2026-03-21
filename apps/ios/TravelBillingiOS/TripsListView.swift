import SwiftUI

struct TripsListView: View {
    @State var trips: [Trip] = []
    @State private var showAddTrip   = false
    @State private var editTrip: Trip?
    @State private var showShareSheet = false
    @State private var itemsToShare: [Any] = []

    private var totalSpent: Double {
        trips.reduce(0) { $0 + NSDecimalNumber(decimal: $1.totalAmount).doubleValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                if trips.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statsHeader
                                .padding(.horizontal)
                                .padding(.top, 4)

                            LazyVStack(spacing: 12) {
                                ForEach($trips) { $trip in
                                    ZStack {
                                        NavigationLink {
                                            TripDetailView(trip: trip) { updated in
                                                if let idx = trips.firstIndex(where: { $0.id == updated.id }) {
                                                    trips[idx] = updated
                                                    Persistence.shared.saveTrips(trips)
                                                }
                                            }
                                        } label: { EmptyView() }
                                        .opacity(0)

                                        TripCardView(trip: trip)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            if let url = ExportService().generateCSV(for: trip) {
                                                itemsToShare = [url]; showShareSheet = true
                                            }
                                        } label: { Label("导出 CSV", systemImage: "doc.text") }
                                        .tint(.green)

                                        Button {
                                            if let url = ExportService().generatePDF(for: trip) {
                                                itemsToShare = [url]; showShareSheet = true
                                            }
                                        } label: { Label("导出 PDF", systemImage: "doc.richtext") }
                                        .tint(.orange)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("删除", role: .destructive) {
                                            if let idx = trips.firstIndex(where: { $0.id == trip.id }) {
                                                trips.remove(at: idx)
                                                Persistence.shared.saveTrips(trips)
                                            }
                                        }
                                        Button("编辑") { editTrip = trip }
                                            .tint(.blue)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("旅行账单")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddTrip = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .onAppear { trips = Persistence.shared.loadTrips() }
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

    private var statsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("行程总数")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Text("\(trips.count) 次")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("累计花费")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Text("¥\(totalSpent, specifier: "%.0f")")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primary)
            }
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cornerRadius))
    }

    private var emptyState: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Theme.primary.opacity(0.18))
                    .frame(width: 130, height: 130)
                Image(systemName: "airplane.departure")
                    .font(.system(size: 52))
                    .foregroundColor(Theme.primary)
            }
            VStack(spacing: 10) {
                Text("开始你的旅程")
                    .font(Theme.titleFont())
                    .foregroundColor(Theme.textPrimary)
                Text("记录每一次旅行的精彩开销")
                    .font(Theme.subheadlineFont())
                    .foregroundColor(Theme.textSecondary)
            }
            Button { showAddTrip = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                    Text("创建第一次旅行").font(Theme.headlineFont())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glassProminent)
        }
    }
}

struct TripCardView: View {
    let trip: Trip

    private var dayCount: Int {
        max(0, Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0)
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "airplane")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.primary)
                .frame(width: 48, height: 48)
                .glassEffect(.regular.tint(Theme.primary), in: .circle)

            VStack(alignment: .leading, spacing: 5) {
                Text(trip.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(trip.startDate.formatted(.dateTime.month().day()), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    if dayCount > 0 {
                        Text("· \(dayCount + 1) 天")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Text("\(trip.bills.count) 笔账单")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                let total = NSDecimalNumber(decimal: trip.totalAmount).doubleValue
                Text("¥\(total, specifier: total >= 10000 ? "%.0f" : "%.2f")")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text(trip.currency)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .glassEffect(.regular, in: .capsule)
            }
        }
        .padding(16)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Theme.cornerRadius))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
