import SwiftUI
import SwiftData

public enum CollectionViewTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case custom = "My Collections"
    case smart = "Smart Filters"
    case trips = "Trips & Plans"
    
    public var id: String { rawValue }
}

public struct SmartCollectionItem: Identifiable {
    public let id: String
    public let name: String
    public let systemIcon: String
    public let colorHex: String
    public let filterDescription: String
}

public struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionModel.createdAt) private var collections: [CollectionModel]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query private var allPlaces: [Place]
    @Query private var allDiscoveries: [Discovery]
    
    @State private var selectedTab: CollectionViewTab = .overview
    @State private var showingAddCollectionSheet = false
    @State private var showingCreateTripSheet = false
    @State private var isGridView: Bool = true
    
    public init() {}
    
    private let smartCollections: [SmartCollectionItem] = [
        SmartCollectionItem(id: "recently_saved", name: "Recently Saved", systemIcon: "clock.fill", colorHex: "#244B3B", filterDescription: "Places added in the last 30 days"),
        SmartCollectionItem(id: "favorites", name: "Favorites", systemIcon: "star.fill", colorHex: "#D97447", filterDescription: "Starred destinations"),
        SmartCollectionItem(id: "visited", name: "Visited Passport", systemIcon: "checkmark.seal.fill", colorHex: "#386641", filterDescription: "Destinations marked as visited"),
        SmartCollectionItem(id: "unvisited", name: "Want to Visit", systemIcon: "circle.dashed", colorHex: "#5B8E7D", filterDescription: "Saved places not yet visited"),
        SmartCollectionItem(id: "with_notes", name: "With Personal Notes", systemIcon: "note.text", colorHex: "#8C6A58", filterDescription: "Places with user itineraries & tips"),
        SmartCollectionItem(id: "with_photos", name: "With Screenshots & Photos", systemIcon: "photo.stack.fill", colorHex: "#B27C61", filterDescription: "Places with image attachments"),
        SmartCollectionItem(id: "from_instagram", name: "From Instagram", systemIcon: "camera.fill", colorHex: "#BC4749", filterDescription: "Saved from Instagram links"),
        SmartCollectionItem(id: "from_youtube", name: "From YouTube", systemIcon: "play.rectangle.fill", colorHex: "#A63D40", filterDescription: "Saved from YouTube videos")
    ]
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                Picker("Tab", selection: $selectedTab) {
                    ForEach(CollectionViewTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(WaypointsColors.background)
                
                // Tab Content
                switch selectedTab {
                case .overview:
                    overviewView
                case .custom:
                    customCollectionsView
                case .smart:
                    smartCollectionsView
                case .trips:
                    TripsListView()
                }
            }
            .background(WaypointsColors.background.ignoresSafeArea())
            .navigationTitle("Collections & Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedTab == .overview || selectedTab == .custom {
                        HStack(spacing: 12) {
                            if selectedTab == .custom {
                                Button {
                                    isGridView.toggle()
                                } label: {
                                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                }
                            }
                            
                            Button {
                                showingAddCollectionSheet = true
                            } label: {
                                Image(systemName: "plus")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCollectionSheet) {
                AddCollectionSheet()
            }
            .sheet(isPresented: $showingCreateTripSheet) {
                CreateTripSheet()
            }
        }
    }
    
    // MARK: - Overview View (Matching Mockup Design)
    
    private var overviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Smart Collections 2x2 Grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("SMART COLLECTIONS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    
                    let gridSmartItems: [(id: String, name: String, emoji: String, subtitle: String)] = [
                        ("favorites", "Favorites", "⭐", "\(filteredPlaces(for: "favorites").count) places"),
                        ("visited", "Visited Passport", "✓", "\(filteredPlaces(for: "visited").count) places"),
                        ("with_photos", "Photos & Media", "📸", "\(filteredPlaces(for: "with_photos").count) places"),
                        ("recently_saved", "Recently Saved", "🕒", "\(filteredPlaces(for: "recently_saved").count) recent")
                    ]
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(gridSmartItems, id: \.id) { item in
                            if let smartItem = smartCollections.first(where: { $0.id == item.id }) {
                                NavigationLink {
                                    SmartCollectionDetailView(item: smartItem, places: filteredPlaces(for: item.id))
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.emoji)
                                            .font(.system(size: 20))
                                            .padding(.bottom, 2)
                                        
                                        Text(item.name)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(WaypointsColors.textPrimary)
                                        
                                        Text(item.subtitle)
                                            .font(.system(size: 11))
                                            .foregroundStyle(WaypointsColors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(WaypointsColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(WaypointsColors.border, lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // 2. Planned Itineraries Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("PLANNED ITINERARIES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        Button {
                            showingCreateTripSheet = true
                        } label: {
                            Text("+ Plan Trip")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(WaypointsColors.deepForest)
                        }
                    }
                    
                    if trips.isEmpty {
                        VStack(spacing: 8) {
                            Text("No trips planned yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button {
                                showingCreateTripSheet = true
                            } label: {
                                Text("Create your first itinerary")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(WaypointsColors.deepForest)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        ForEach(trips) { trip in
                            tripOverviewCard(trip)
                        }
                    }
                }
                
                // 3. Custom Collections Preview
                if !collections.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("MY COLLECTIONS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Button {
                                selectedTab = .custom
                            } label: {
                                Text("View All (\(collections.count))")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(WaypointsColors.deepForest)
                            }
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(collections.prefix(4)) { collection in
                                NavigationLink {
                                    CollectionDetailView(collection: collection)
                                } label: {
                                    collectionCard(collection)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
    
    private func tripOverviewCard(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(WaypointsColors.deepForest)
                    
                    Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) – \(trip.endDate.formatted(date: .abbreviated, time: .omitted)) • \(trip.durationInDays) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(trip.places.count) STOPS")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(WaypointsColors.deepForest.opacity(0.1))
                    .foregroundStyle(WaypointsColors.deepForest)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Stops route preview
            let sortedDays = trip.days.sorted { $0.dayNumber < $1.dayNumber }
            if !sortedDays.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sortedDays.prefix(2)) { day in
                        if let firstStop = day.sortedStops.first {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(WaypointsColors.deepForest)
                                    .frame(width: 6, height: 6)
                                
                                Text("Day \(day.dayNumber): \(day.title)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(WaypointsColors.deepForest)
                                
                                Text("• \(firstStop.placeName)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.leading, 4)
                .overlay(
                    Rectangle()
                        .fill(WaypointsColors.deepForest.opacity(0.2))
                        .frame(width: 2)
                        .padding(.vertical, 4),
                    alignment: .leading
                )
            }
            
            NavigationLink {
                TripDetailView(trip: trip)
            } label: {
                HStack {
                    Spacer()
                    Text("Open Day-by-Day Route")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WaypointsColors.deepForest)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WaypointsColors.deepForest)
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(WaypointsColors.mintMist.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Custom Collections
    
    private var customCollectionsView: some View {
        ScrollView {
            if collections.isEmpty {
                emptyState
            } else if isGridView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(collections) { collection in
                        NavigationLink {
                            CollectionDetailView(collection: collection)
                        } label: {
                            collectionCard(collection)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(collections) { collection in
                        NavigationLink {
                            CollectionDetailView(collection: collection)
                        } label: {
                            collectionListRow(collection)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Smart Collections View
    
    private var smartCollectionsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(smartCollections) { item in
                    NavigationLink {
                        SmartCollectionDetailView(item: item, places: filteredPlaces(for: item.id))
                    } label: {
                        smartCollectionRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }
    
    private func filteredPlaces(for smartId: String) -> [Place] {
        switch smartId {
        case "recently_saved":
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return allPlaces.filter { $0.createdAt >= cutoff }
        case "favorites":
            return allPlaces.filter { $0.isFavorite }
        case "visited":
            return allPlaces.filter { $0.isVisited }
        case "unvisited":
            return allPlaces.filter { !$0.isVisited }
        case "with_notes":
            return allPlaces.filter { !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case "with_photos":
            return allPlaces.filter { !$0.imageFileNames.isEmpty }
        case "from_instagram":
            return allPlaces.filter { ($0.sourceURL?.lowercased().contains("instagram") ?? false) || ($0.source.lowercased().contains("instagram")) }
        case "from_youtube":
            return allPlaces.filter { ($0.sourceURL?.lowercased().contains("youtube") ?? false) || ($0.sourceURL?.lowercased().contains("youtu.be") ?? false) }
        default:
            return allPlaces
        }
    }
    
    private func smartCollectionRow(_ item: SmartCollectionItem) -> some View {
        let count = filteredPlaces(for: item.id).count
        return HStack(spacing: 14) {
            Circle()
                .fill(Color(hex: item.colorHex).opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: item.systemIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: item.colorHex))
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WaypointsColors.deepForest)
                
                Text(item.filterDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(WaypointsColors.brandPrimary.opacity(0.1))
                .foregroundStyle(WaypointsColors.brandPrimary)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func collectionCard(_ collection: CollectionModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: collection.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: collection.systemIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: collection.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WaypointsColors.textPrimary)
                    .lineLimit(1)
                
                Text("\(collection.places.count) place\(collection.places.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(WaypointsColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func collectionListRow(_ collection: CollectionModel) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(hex: collection.colorHex).opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: collection.systemIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: collection.colorHex))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WaypointsColors.textPrimary)
                
                Text("\(collection.places.count) saved waypoint\(collection.places.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(WaypointsColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(WaypointsColors.textSecondary)
        }
        .padding(14)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 54))
                .foregroundStyle(WaypointsColors.deepForest.opacity(0.3))
            
            Text("No Collections")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text("Organize your travel destinations and saved spots by trip, region, or theme.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingAddCollectionSheet = true
            } label: {
                Label("New Collection", systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(WaypointsColors.deepForest)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Smart Collection Detail View

public struct SmartCollectionDetailView: View {
    public let item: SmartCollectionItem
    public let places: [Place]
    
    public init(item: SmartCollectionItem, places: [Place]) {
        self.item = item
        self.places = places
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                Circle()
                    .fill(Color(hex: item.colorHex).opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: item.systemIcon)
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: item.colorHex))
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(WaypointsTypography.display(20))
                        .foregroundStyle(WaypointsColors.deepForest)
                    Text("\(places.count) waypoint\(places.count == 1 ? "" : "s") • \(item.filterDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            
            if places.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No Matching Waypoints")
                        .font(.headline)
                        .foregroundStyle(WaypointsColors.deepForest)
                    Text("No waypoints currently match this dynamic filter.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(places) { place in
                        NavigationLink {
                            PlaceDetailView(place: place)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(WaypointsColors.deepForest)
                                    if !place.country.isEmpty {
                                        Text(place.country)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(place.formattedCoordinates)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if place.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(WaypointsColors.sunsetAmber)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(WaypointsColors.sandLight)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Add Collection Sheet

public struct AddCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var selectedColorHex: String = "#164B43"
    @State private var errorMessage: String? = nil
    
    let icons = ["folder.fill", "star.fill", "heart.fill", "airplane", "tent.fill", "cup.and.saucer.fill", "camera.fill", "figure.walk", "mountain.2.fill", "water.waves"]
    let colors = ["#164B43", "#101F33", "#FF785A", "#267A6E", "#E09F3E", "#386641", "#5B8E7D", "#8C6A58"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Collection Name") {
                    TextField("Name (e.g. Kyoto Cafes, Summer Roadtrip)", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : Color.clear)
                                    .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(selectedColorHex == hex ? 0.4 : 0), lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            errorMessage = "Please enter a collection name."
                            return
                        }
                        let col = CollectionModel(name: trimmed, systemIcon: selectedIcon, colorHex: selectedColorHex)
                        modelContext.insert(col)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
