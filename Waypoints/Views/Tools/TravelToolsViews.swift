import SwiftUI
import SwiftData
import CoreLocation

// MARK: - Duplicate Review Tool

public struct DuplicateCandidatePair: Identifiable {
    public let id = UUID()
    public let placeA: Place
    public let placeB: Place
    public let distanceMeters: Double
    public let reason: String
}

public struct DuplicateReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allPlaces: [Place]
    
    @State private var duplicatePairs: [DuplicateCandidatePair] = []
    @State private var dismissedPairIds: Set<UUID> = []
    @State private var isScanning = false
    @State private var statusMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Duplicate Detector")
                        .font(WaypointsTypography.display(22))
                        .foregroundStyle(WaypointsColors.deepForest)
                    Text("Waypoints scans your saved destinations for identical coordinates (within 150m) or matching names so you can merge notes and media.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if isScanning {
                    ProgressView("Analyzing destinations…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(32)
                } else if activePairs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(WaypointsColors.deepForest)
                        Text("No Duplicates Found")
                            .font(.headline)
                            .foregroundStyle(WaypointsColors.deepForest)
                        Text("All saved destinations have distinct coordinates and names.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(36)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Text("\(activePairs.count) CANDIDATE DUPLICATE\(activePairs.count == 1 ? "" : "S")")
                        .font(WaypointsTypography.eyebrow)
                        .foregroundStyle(.secondary)
                    
                    ForEach(activePairs) { pair in
                        duplicateCard(pair: pair)
                    }
                }
            }
            .padding(16)
        }
        .background(WaypointsColors.sandLight.ignoresSafeArea())
        .navigationTitle("Duplicate Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scanForDuplicates()
        }
    }
    
    private var activePairs: [DuplicateCandidatePair] {
        duplicatePairs.filter { !dismissedPairIds.contains($0.id) }
    }
    
    private func scanForDuplicates() {
        isScanning = true
        var results: [DuplicateCandidatePair] = []
        let places = allPlaces
        
        for i in 0..<places.count {
            for j in (i + 1)..<places.count {
                let p1 = places[i]
                let p2 = places[j]
                
                let distMeters = CoordinateMath.haversineDistanceMeters(
                    lat1: p1.latitude, lon1: p1.longitude,
                    lat2: p2.latitude, lon2: p2.longitude
                )
                
                let name1 = p1.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let name2 = p2.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                var matched = false
                var reason = ""
                
                if distMeters <= 150.0 && !name1.isEmpty && !name2.isEmpty {
                    matched = true
                    reason = String(format: "Coordinates are within %.0f meters", distMeters)
                } else if name1 == name2 && !name1.isEmpty {
                    matched = true
                    reason = "Identical place name"
                }
                
                if matched {
                    results.append(DuplicateCandidatePair(
                        placeA: p1,
                        placeB: p2,
                        distanceMeters: distMeters,
                        reason: reason
                    ))
                }
            }
        }
        self.duplicatePairs = results
        self.isScanning = false
    }
    
    private func duplicateCard(pair: DuplicateCandidatePair) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(pair.reason, systemName: "arrow.triangle.merge")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(WaypointsColors.terracotta)
                Spacer()
                Text(String(format: "%.0f m apart", pair.distanceMeters))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .top, spacing: 12) {
                placeMiniSummary(place: pair.placeA, badge: "Primary")
                Divider()
                placeMiniSummary(place: pair.placeB, badge: "Duplicate")
            }
            
            HStack(spacing: 12) {
                Button {
                    mergePlaces(pair: pair)
                } label: {
                    Text("Merge Into Primary")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(WaypointsColors.deepForest)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button {
                    dismissedPairIds.insert(pair.id)
                } label: {
                    Text("Keep Both")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func placeMiniSummary(place: Place, badge: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(badge.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            Text(place.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WaypointsColors.deepForest)
                .lineLimit(1)
            Text(place.formattedCoordinates)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
            if !place.imageFileNames.isEmpty {
                Text("\(place.imageFileNames.count) photo(s)")
                    .font(.caption2)
                    .foregroundStyle(WaypointsColors.deepForest)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func mergePlaces(pair: DuplicateCandidatePair) {
        let pA = pair.placeA
        let pB = pair.placeB
        
        // Merge notes
        if !pB.note.isEmpty && !pA.note.contains(pB.note) {
            pA.note = pA.note.isEmpty ? pB.note : "\(pA.note)\n\nMerged notes: \(pB.note)"
        }
        
        // Merge photos
        for img in pB.imageFileNames {
            pA.addImageFileName(img)
        }
        
        // Merge source references
        for ref in pB.sourceReferences {
            pA.addSourceReference(ref)
        }
        
        // Merge favorites/visited state
        if pB.isFavorite { pA.isFavorite = true }
        if pB.isVisited { pA.isVisited = true }
        
        // Merge collections
        for col in pB.collections {
            if !pA.collections.contains(where: { $0.id == col.id }) {
                pA.collections.append(col)
            }
        }
        
        pA.updatedAt = Date()
        modelContext.delete(pB)
        try? modelContext.save()
        
        dismissedPairIds.insert(pair.id)
    }
}

// MARK: - Discovery Cleanup Tool

public struct DiscoveryCleanupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Discovery.createdAt, order: .reverse) private var allDiscoveries: [Discovery]
    
    @State private var selectedIds: Set<String> = []
    @State private var showingDeleteConfirmation = false
    
    public init() {}
    
    private var unconfirmedDiscoveries: [Discovery] {
        allDiscoveries.filter { $0.status == .failed || $0.status == .needsInfo || $0.status == .savedAwaiting }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if unconfirmedDiscoveries.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(WaypointsColors.deepForest.opacity(0.3))
                    Text("Inbox is Clean")
                        .font(WaypointsTypography.title(18))
                        .foregroundStyle(WaypointsColors.deepForest)
                    Text("No failed or unconfirmed discovery drafts in your queue.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(24)
            } else {
                HStack {
                    Button(selectedIds.count == unconfirmedDiscoveries.count ? "Deselect All" : "Select All") {
                        if selectedIds.count == unconfirmedDiscoveries.count {
                            selectedIds.removeAll()
                        } else {
                            selectedIds = Set(unconfirmedDiscoveries.map { $0.id })
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(WaypointsColors.deepForest)
                    
                    Spacer()
                    
                    if !selectedIds.isEmpty {
                        Button("Delete Selected (\(selectedIds.count))", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                List {
                    ForEach(unconfirmedDiscoveries) { item in
                        HStack(spacing: 12) {
                            Button {
                                if selectedIds.contains(item.id) {
                                    selectedIds.remove(item.id)
                                } else {
                                    selectedIds.insert(item.id)
                                }
                            } label: {
                                Image(systemName: selectedIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIds.contains(item.id) ? WaypointsColors.deepForest : .secondary)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.caption.isEmpty ? item.originalURL : item.caption)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(WaypointsColors.deepForest)
                                    .lineLimit(1)
                                
                                HStack(spacing: 6) {
                                    Text(item.status.displayLabel)
                                        .font(.caption2)
                                        .foregroundStyle(Color(hex: item.status.badgeColorHex))
                                    Text("• \(item.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(WaypointsColors.sandLight)
        .navigationTitle("Cleanup Discoveries")
        .alert("Delete Discoveries", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) unconfirmed discovery drafts?")
        }
    }
    
    private func deleteSelected() {
        for discovery in unconfirmedDiscoveries where selectedIds.contains(discovery.id) {
            modelContext.delete(discovery)
        }
        try? modelContext.save()
        selectedIds.removeAll()
    }
}

// MARK: - Nearby Saved Places Tool

public final class SimpleLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published public var userLocation: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let manager = CLLocationManager()
    
    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }
    
    public func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
}

public struct NearbyPlacesView: View {
    @Query private var places: [Place]
    @StateObject private var locationManager = SimpleLocationManager()
    
    public init() {}
    
    private var sortedPlaces: [(place: Place, distanceKm: Double)] {
        guard let userLoc = locationManager.userLocation else {
            return places.map { ($0, 0.0) }
        }
        return places.map { place in
            let dist = CoordinateMath.haversineDistanceKm(
                lat1: userLoc.coordinate.latitude, lon1: userLoc.coordinate.longitude,
                lat2: place.latitude, lon2: place.longitude
            )
            return (place, dist)
        }.sorted { $0.distanceKm < $1.distanceKm }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if locationManager.authorizationStatus == .notDetermined {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "location.circle")
                        .font(.system(size: 54))
                        .foregroundStyle(WaypointsColors.deepForest)
                    Text("Find Saved Spots Near You")
                        .font(WaypointsTypography.display(20))
                        .foregroundStyle(WaypointsColors.deepForest)
                    Text("Enable location permissions to calculate accurate distance and sort your saved destinations by proximity.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button {
                        locationManager.requestPermission()
                    } label: {
                        Text("Enable Location Access")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(WaypointsColors.deepForest)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
            } else if places.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("No Saved Waypoints")
                        .font(.headline)
                        .foregroundStyle(WaypointsColors.deepForest)
                    Spacer()
                }
            } else {
                List {
                    ForEach(sortedPlaces, id: \.place.id) { item in
                        NavigationLink {
                            PlaceDetailView(place: item.place)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.place.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(WaypointsColors.deepForest)
                                    if !item.place.country.isEmpty {
                                        Text(item.place.country)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if locationManager.userLocation != nil {
                                    Text(String(format: "%.1f km", item.distanceKm))
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(WaypointsColors.deepForest)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(WaypointsColors.mintMist)
                                        .clipShape(Capsule())
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
        .navigationTitle("Near Me")
        .onAppear {
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                locationManager.requestPermission()
            }
        }
    }
}
