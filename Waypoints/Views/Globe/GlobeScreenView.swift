import SwiftUI
import SwiftData

public enum GlobeDisplayMode: String, CaseIterable, Identifiable {
    case explore = "Explore"
    case pickLocation = "Tap to Pin"
    case tripMode = "Trip Focus"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .explore: return "globe.europe.africa.fill"
        case .pickLocation: return "hand.tap.fill"
        case .tripMode: return "airplane"
        }
    }
}

public struct GlobeScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.createdAt, order: .reverse) private var allPlaces: [Place]
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query(sort: \CollectionModel.name) private var collections: [CollectionModel]
    
    @State private var selectedPlace: Place? = nil
    @State private var displayMode: GlobeDisplayMode = .explore
    @State private var selectedTripId: String? = nil
    @State private var selectedCollectionId: String? = nil
    @State private var tappedCoordinate: (lat: Double, lon: Double)? = nil
    @State private var showingSaveTappedPinSheet: Bool = false
    @State private var showingQuickAddSheet: Bool = false
    @State private var showingSearchSheet: Bool = false
    @State private var use3DGlobe: Bool = true
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    public init() {}
    
    private var displayedPlaces: [Place] {
        switch displayMode {
        case .explore, .pickLocation:
            if let colId = selectedCollectionId {
                return allPlaces.filter { $0.collections.contains(where: { $0.id == colId }) }
            }
            return allPlaces
            
        case .tripMode:
            if let tripId = selectedTripId, let trip = trips.first(where: { $0.id == tripId }) {
                return trip.places
            } else if let firstTrip = trips.first {
                return firstTrip.places
            }
            return allPlaces
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Warm Sand Canvas Background
                WaypointsColors.sandLight
                    .ignoresSafeArea()
                
                // Hardware-Accelerated 3D SceneKit Globe or Cartographic Canvas Globe
                if use3DGlobe {
                    SceneKitGlobeView(
                        places: displayedPlaces,
                        selectedPlace: selectedPlace,
                        isTapModeActive: displayMode == .pickLocation,
                        onPlaceSelected: { place in
                            hapticFeedback.impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedPlace = place
                            }
                        },
                        onGlobeTapped: { lat, lon in
                            hapticFeedback.impactOccurred()
                            tappedCoordinate = (lat, lon)
                            showingSaveTappedPinSheet = true
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    NativeGlobeView(
                        places: displayedPlaces,
                        selectedPlace: selectedPlace,
                        isTapModeActive: displayMode == .pickLocation,
                        onPlaceSelected: { place in
                            hapticFeedback.impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedPlace = place
                            }
                        },
                        onGlobeTapped: { lat, lon in
                            hapticFeedback.impactOccurred()
                            tappedCoordinate = (lat, lon)
                            showingSaveTappedPinSheet = true
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Overlay Controls (Top & Bottom)
                VStack {
                    topControlsBar
                    
                    // Filter Chips Bar (in Trip or Collection mode)
                    if displayMode == .tripMode {
                        tripFilterBar
                    } else if !collections.isEmpty && displayMode == .explore {
                        collectionFilterBar
                    }
                    
                    Spacer()
                    
                    // Bottom Controls: Selected Place Card & Floating Add Action
                    VStack(spacing: 12) {
                        if let selected = selectedPlace {
                            placePreviewCard(selected)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        bottomActionBar
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSaveTappedPinSheet) {
                if let coord = tappedCoordinate {
                    SaveGlobePinSheet(latitude: coord.lat, longitude: coord.lon)
                }
            }
            .sheet(item: $selectedPlace) { place in
                NavigationStack {
                    PlaceDetailView(place: place)
                }
            }
            .sheet(isPresented: $showingQuickAddSheet) {
                AddDiscoverySheet { url, caption, collection, images in
                    let disc = Discovery(originalURL: url, caption: caption, collectionName: collection)
                    disc.imageFileNames = images
                    modelContext.insert(disc)
                    try? modelContext.save()
                    Task {
                        _ = await DiscoveryPipeline.shared.identifyLocation(for: disc)
                        try? modelContext.save()
                    }
                }
            }
            .sheet(isPresented: $showingSearchSheet) {
                GlobeSearchSheet(places: allPlaces) { chosen in
                    selectedPlace = chosen
                }
            }
        }
    }
    
    // MARK: - Top Controls Bar
    
    private var topControlsBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Waypoints")
                    .font(WaypointsTypography.display(22))
                    .foregroundStyle(WaypointsColors.deepForest)
                
                Text("\(displayedPlaces.count) visible pin\(displayedPlaces.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Mode Selector Pill
            HStack(spacing: 4) {
                ForEach(GlobeDisplayMode.allCases) { mode in
                    Button {
                        hapticFeedback.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            displayMode = mode
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                            if displayMode == mode {
                                Text(mode.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(displayMode == mode ? WaypointsColors.deepForest : Color.clear)
                        .foregroundStyle(displayMode == mode ? .white : WaypointsColors.deepForest)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(3)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            
            // 3D SceneKit vs Cartographic Globe Toggle
            Button {
                hapticFeedback.impactOccurred()
                withAnimation(.easeInOut(duration: 0.2)) {
                    use3DGlobe.toggle()
                }
            } label: {
                Image(systemName: use3DGlobe ? "globe.americas.fill" : "map")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(9)
                    .background(use3DGlobe ? WaypointsColors.deepForest : Color.white)
                    .foregroundStyle(use3DGlobe ? .white : WaypointsColors.deepForest)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            
            // Search button
            Button {
                showingSearchSheet = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(9)
                    .background(Color.white)
                    .foregroundStyle(WaypointsColors.deepForest)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Trip Filter Bar
    
    private var tripFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if trips.isEmpty {
                    Text("No trips planned yet. Create trips in the Trips tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(trips) { trip in
                        let isSelected = (selectedTripId ?? trips.first?.id) == trip.id
                        Button {
                            withAnimation { selectedTripId = trip.id }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "airplane")
                                Text(trip.name)
                                Text("(\(trip.places.count))")
                                    .font(.caption2)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color(hex: trip.colorHex) : Color.white)
                            .foregroundStyle(isSelected ? .white : WaypointsColors.deepForest)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Collection Filter Bar
    
    private var collectionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation { selectedCollectionId = nil }
                } label: {
                    Text("All Pins")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCollectionId == nil ? WaypointsColors.deepForest : Color.white)
                        .foregroundStyle(selectedCollectionId == nil ? .white : WaypointsColors.deepForest)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                }
                
                ForEach(collections) { col in
                    let isSelected = selectedCollectionId == col.id
                    Button {
                        withAnimation { selectedCollectionId = isSelected ? nil : col.id }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: col.systemIcon)
                            Text(col.name)
                            Text("(\(col.places.count))")
                                .font(.caption2)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color(hex: col.colorHex) : Color.white)
                        .foregroundStyle(isSelected ? .white : WaypointsColors.deepForest)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Selected Place Card
    
    private func placePreviewCard(_ place: Place) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WaypointsColors.deepForest)
                        .lineLimit(1)
                    
                    if place.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(WaypointsColors.sunsetAmber)
                    }
                    if place.isVisited {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(WaypointsColors.deepForest)
                    }
                }
                
                if !place.country.isEmpty {
                    Text(place.country)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 6) {
                    Text(place.formattedCoordinates)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text(place.provenance.displayLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(WaypointsColors.deepForest)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WaypointsColors.mintMist)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            Button {
                selectedPlace = place
            } label: {
                Text("View")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(WaypointsColors.deepForest)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            Button {
                selectedPlace = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 20))
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack {
            if displayMode == .pickLocation {
                HStack(spacing: 6) {
                    Image(systemName: "cross.circle.fill")
                        .foregroundStyle(WaypointsColors.terracotta)
                    Text("Tap anywhere on Earth to drop pin")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WaypointsColors.deepForest)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
            }
            
            Spacer()
            
            // Floating Quick Add Discovery Button
            Button {
                showingQuickAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("Add Discovery")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(WaypointsColors.deepForest)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: WaypointsColors.deepForest.opacity(0.35), radius: 10, x: 0, y: 4)
            }
        }
    }
}

// MARK: - Quick Search Sheet

public struct GlobeSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let places: [Place]
    public var onSelect: (Place) -> Void
    
    @State private var query = ""
    @State private var worldResults: [LocationCandidate] = []
    @State private var isSearchingWorld = false
    
    private var localMatches: [Place] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()
        return places.filter { $0.name.lowercased().contains(q) || $0.country.lowercased().contains(q) }
    }
    
    public var body: some View {
        NavigationStack {
            List {
                if !localMatches.isEmpty {
                    Section("Saved Waypoints") {
                        ForEach(localMatches) { place in
                            Button {
                                onSelect(place)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(WaypointsColors.deepForest)
                                    Text("\(place.country) • \(place.formattedCoordinates)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                
                if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                    Section("Search the World (Photon OSM)") {
                        if isSearchingWorld {
                            HStack {
                                ProgressView()
                                Text("Searching worldwide destinations…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else if worldResults.isEmpty {
                            Button("Search worldwide for \"\(query)\"") {
                                searchWorld()
                            }
                            .foregroundStyle(WaypointsColors.deepForest)
                        } else {
                            ForEach(worldResults) { candidate in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(candidate.name)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(candidate.country)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search saved waypoints or cities…")
            .navigationTitle("Search Destinations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func searchWorld() {
        isSearchingWorld = true
        Task {
            let matches = await GeocodingEngine.shared.search(query: query)
            await MainActor.run {
                worldResults = matches
                isSearchingWorld = false
            }
        }
    }
}
