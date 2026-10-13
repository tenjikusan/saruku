import SwiftUI
import SwiftData

public struct GlobeScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.createdAt, order: .reverse) private var places: [Place]
    
    @State private var selectedPlace: Place? = nil
    @State private var isTapModeActive: Bool = false
    @State private var tappedCoordinate: (lat: Double, lon: Double)? = nil
    @State private var showingPlaceDetail: Bool = false
    @State private var showingSaveTappedPinSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                WaypointsColors.sandLight
                    .ignoresSafeArea()
                
                // Native 3D Globe
                NativeGlobeView(
                    places: places,
                    selectedPlace: selectedPlace,
                    isTapModeActive: isTapModeActive,
                    onPlaceSelected: { place in
                        selectedPlace = place
                    },
                    onGlobeTapped: { lat, lon in
                        tappedCoordinate = (lat, lon)
                        showingSaveTappedPinSheet = true
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Top Overlay Controls
                VStack {
                    topControlsBar
                    Spacer()
                    
                    // Bottom Selection Card
                    if let selected = selectedPlace {
                        placePreviewCard(selected)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(16)
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
        }
    }
    
    private var topControlsBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Waypoints")
                    .font(WaypointsTypography.display(22))
                    .foregroundStyle(WaypointsColors.deepForest)
                
                Text("\(places.count) saved pin\(places.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                isTapModeActive.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isTapModeActive ? "hand.tap.fill" : "hand.tap")
                    Text(isTapModeActive ? "Tap Mode ON" : "Tap to Pin")
                }
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isTapModeActive ? WaypointsColors.terracotta : Color.white)
                .foregroundStyle(isTapModeActive ? .white : WaypointsColors.deepForest)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
            }
        }
        .padding(.top, 8)
    }
    
    private func placePreviewCard(_ place: Place) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WaypointsColors.deepForest)
                    .lineLimit(1)
                
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
                    .font(.system(size: 18))
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

public struct SaveGlobePinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionModel.name) private var collections: [CollectionModel]
    
    public let latitude: Double
    public let longitude: Double
    
    @State private var name: String = ""
    @State private var country: String = ""
    @State private var note: String = ""
    @State private var selectedCollectionIds: Set<String> = []
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Globe Pin Location") {
                    HStack {
                        Text("Coordinates")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.4f°, %.4f°", latitude, longitude))
                            .font(.system(size: 14, design: .monospaced))
                    }
                    Text("Inverse orthographic projection via tap")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Place Details") {
                    TextField("Place name", text: $name)
                    TextField("Country / Region (optional)", text: $country)
                }
                
                if !collections.isEmpty {
                    Section("Collections") {
                        ForEach(collections) { col in
                            HStack {
                                Image(systemName: col.systemIcon)
                                    .foregroundStyle(Color(hex: col.colorHex))
                                Text(col.name)
                                Spacer()
                                if selectedCollectionIds.contains(col.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(WaypointsColors.deepForest)
                                        .fontWeight(.semibold)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedCollectionIds.contains(col.id) {
                                    selectedCollectionIds.remove(col.id)
                                } else {
                                    selectedCollectionIds.insert(col.id)
                                }
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Save Waypoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Pin") {
                        savePin()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func savePin() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let place = Place(
            name: trimmedName,
            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude,
            longitude: longitude,
            precision: "exact",
            provenance: .globeTap,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            source: "Globe tap",
            evidence: "Manual tap on 3D Earth globe"
        )
        
        place.collections = collections.filter { selectedCollectionIds.contains($0.id) }
        modelContext.insert(place)
        try? modelContext.save()
        dismiss()
    }
}
