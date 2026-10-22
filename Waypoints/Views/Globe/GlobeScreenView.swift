import SwiftUI
import SwiftData

public enum GlobeDisplayMode: String, CaseIterable, Identifiable {
    case explore = "Explore"
    case pickLocation = "Tap to Pin"
    case tripMode = "Trips"
    
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
    @State private var showingPlaceDetail: Bool = false
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
                // Adaptive Porcelain / Deep Ocean Background
                WaypointsColors.background
                    .ignoresSafeArea()
                
                // Hardware-Accelerated 3D SceneKit Globe or Cartographic Canvas Globe
                Group {
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
                    }
                }
                .ignoresSafeArea()
                
                // Floating Overlay Controls (Top & Bottom)
                VStack(spacing: 8) {
                    topControlsBar
                    
                    // Filter Chips Bar (in Trip or Collection mode)
                    if displayMode == .tripMode {
                        tripFilterBar
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else if !collections.isEmpty && displayMode == .explore {
                        collectionFilterBar
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    Spacer()
                    
                    // Bottom Controls: Selected Place Card & Floating Add Action
                    VStack(spacing: 12) {
                        if let selected = selectedPlace {
                            placePreviewCard(selected)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity.combined(with: .scale(scale: 0.95))
                                ))
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
            .sheet(isPresented: $showingPlaceDetail) {
                if let place = selectedPlace {
                    NavigationStack {
                        PlaceDetailView(place: place)
                    }
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
        VStack(spacing: 8) {
            // Header: Branding & Action Utilities
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Text("Waypoints")
                        .font(WaypointsTypography.display(24))
                        .foregroundStyle(WaypointsColors.textPrimary)
                    
                    Text("\(displayedPlaces.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(WaypointsColors.brandPrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(WaypointsColors.brandPrimary.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // 3D SceneKit vs Cartographic Globe Toggle
                    Button {
                        hapticFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            use3DGlobe.toggle()
                        }
                    } label: {
                        Image(systemName: use3DGlobe ? "globe.americas.fill" : "map.fill")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(use3DGlobe ? WaypointsColors.brandPrimary : WaypointsColors.surface)
                            .foregroundStyle(use3DGlobe ? .white : WaypointsColors.brandPrimary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(WaypointsColors.border, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    }
                    
                    // Search button
                    Button {
                        hapticFeedback.impactOccurred()
                        showingSearchSheet = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(WaypointsColors.surface)
                            .foregroundStyle(WaypointsColors.textPrimary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(WaypointsColors.border, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    }
                }
            }
            .padding(.top, 4)
            
            // Mode Selector Floating Capsule: [Explore | Tap to Pin | Trips]
            HStack(spacing: 4) {
                ForEach(GlobeDisplayMode.allCases) { mode in
                    let isSelected = displayMode == mode
                    Button {
                        hapticFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            displayMode = mode
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSelected ? WaypointsColors.brandPrimary : Color.clear)
                        .foregroundStyle(isSelected ? Color.white : WaypointsColors.textSecondary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(3)
            .background(WaypointsColors.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(WaypointsColors.border, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Trip Filter Bar
    
    private var tripFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if trips.isEmpty {
                    Text("No trips planned yet. Create trips in the Trips tab.")
                        .font(.caption)
                        .foregroundStyle(WaypointsColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(WaypointsColors.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(WaypointsColors.border, lineWidth: 1))
                } else {
                    ForEach(trips) { trip in
                        let isSelected = (selectedTripId ?? trips.first?.id) == trip.id
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedTripId = trip.id }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "airplane")
                                Text(trip.name)
                                Text("(\(trip.places.count))")
                                    .font(.caption2)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color(hex: trip.colorHex) : WaypointsColors.surface)
                            .foregroundStyle(isSelected ? .white : WaypointsColors.textPrimary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? Color.clear : WaypointsColors.border, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
    }
    
    // MARK: - Collection Filter Bar
    
    private var collectionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedCollectionId = nil }
                } label: {
                    Text("All Pins")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCollectionId == nil ? WaypointsColors.brandPrimary : WaypointsColors.surface)
                        .foregroundStyle(selectedCollectionId == nil ? .white : WaypointsColors.textPrimary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(selectedCollectionId == nil ? Color.clear : WaypointsColors.border, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                }
                
                ForEach(collections) { col in
                    let isSelected = selectedCollectionId == col.id
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedCollectionId = isSelected ? nil : col.id }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: col.systemIcon)
                            Text(col.name)
                            Text("(\(col.places.count))")
                                .font(.caption2)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color(hex: col.colorHex) : WaypointsColors.surface)
                        .foregroundStyle(isSelected ? .white : WaypointsColors.textPrimary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSelected ? Color.clear : WaypointsColors.border, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                    }
                }
            }
            .padding(.top, 2)
        }
    }
    
    // MARK: - Selected Place Card
    
    private func placePreviewCard(_ place: Place) -> some View {
        HStack(spacing: 12) {
            // Category Emoji or Media Thumbnail Box
            ZStack {
                if let photo = place.photoFileNames.first,
                   let img = LocalMediaStorage.shared.loadImage(fileName: photo) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(WaypointsColors.brandPrimary.opacity(0.08))
                        .frame(width: 54, height: 54)
                    Text(place.categoryEmoji)
                        .font(.system(size: 26))
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsColors.border, lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(place.categoryDisplay.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(WaypointsColors.brandPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WaypointsColors.brandPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    if place.isFavorite {
                        Text("★")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "#E09F3E"))
                    }
                    if place.isVisited {
                        Text("✓")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(WaypointsColors.brandPrimary)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPlace = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(WaypointsColors.textSecondary)
                            .frame(width: 22, height: 22)
                            .background(WaypointsColors.border.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                
                Text(place.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(WaypointsColors.textPrimary)
                    .lineLimit(1)
                
                let locationText = [place.city, place.region, place.country].filter { !$0.isEmpty }.joined(separator: ", ")
                if !locationText.isEmpty {
                    Text(locationText)
                        .font(.caption)
                        .foregroundStyle(WaypointsColors.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(place.formattedCoordinates)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(WaypointsColors.textSecondary)
                }
            }
            
            // Detail Navigation Arrow Button
            Button {
                hapticFeedback.impactOccurred()
                showingPlaceDetail = true
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(WaypointsColors.brandPrimary)
                    .clipShape(Circle())
                    .shadow(color: WaypointsColors.brandPrimary.opacity(0.35), radius: 6, x: 0, y: 2)
            }
        }
        .padding(12)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack {
            if displayMode == .pickLocation {
                HStack(spacing: 6) {
                    Circle()
                        .fill(WaypointsColors.accentCoral)
                        .frame(width: 8, height: 8)
                    Text("Tap Earth to drop pin")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WaypointsColors.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(WaypointsColors.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(WaypointsColors.border, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            
            Spacer()
            
            // Floating Quick Add Discovery Button
            Button {
                hapticFeedback.impactOccurred()
                showingQuickAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Add Discovery")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(WaypointsColors.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: WaypointsColors.brandPrimary.opacity(0.35), radius: 10, x: 0, y: 4)
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
