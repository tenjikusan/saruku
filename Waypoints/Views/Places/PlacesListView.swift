import SwiftUI
import SwiftData

public struct PlacesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.createdAt, order: .reverse) private var places: [Place]
    @Query(sort: \CollectionModel.name) private var collections: [CollectionModel]
    
    @State private var searchText = ""
    @State private var selectedFilter: PlaceFilter = .all
    @State private var selectedCollectionId: String? = nil
    @State private var showingAddPlaceSheet = false
    
    public enum PlaceFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case favorites = "Favorites"
        case visited = "Visited"
        case unvisited = "Want to Visit"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Segmented Control
                filterBar
                
                // Content List
                if filteredPlaces.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredPlaces) { place in
                            NavigationLink {
                                PlaceDetailView(place: place)
                            } label: {
                                placeRow(place)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    place.isFavorite.toggle()
                                    place.updatedAt = Date()
                                    try? modelContext.save()
                                } label: {
                                    Label(place.isFavorite ? "Unfavorite" : "Favorite",
                                          systemName: place.isFavorite ? "star.slash" : "star.fill")
                                }
                                .tint(WaypointsColors.sunsetAmber)
                                
                                Button {
                                    place.isVisited.toggle()
                                    place.updatedAt = Date()
                                    try? modelContext.save()
                                } label: {
                                    Label(place.isVisited ? "Unvisited" : "Visited",
                                          systemName: place.isVisited ? "circle" : "checkmark.seal.fill")
                                }
                                .tint(WaypointsColors.deepForest)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(place)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemName: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $searchText, prompt: "Search places, countries, notes…")
            .navigationTitle("Waypoints")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddPlaceSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddPlaceSheet) {
                AddManualPlaceSheet()
            }
        }
    }
    
    private var filterBar: some View {
        VStack(spacing: 8) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(PlaceFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            
            if !collections.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedCollectionId = nil
                        } label: {
                            Text("All Collections")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCollectionId == nil ? WaypointsColors.deepForest : Color.white)
                                .foregroundStyle(selectedCollectionId == nil ? .white : WaypointsColors.deepForest)
                                .clipShape(Capsule())
                        }
                        
                        ForEach(collections) { col in
                            Button {
                                selectedCollectionId = (selectedCollectionId == col.id) ? nil : col.id
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: col.systemIcon)
                                    Text(col.name)
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCollectionId == col.id ? Color(hex: col.colorHex) : Color.white)
                                .foregroundStyle(selectedCollectionId == col.id ? .white : Color(hex: col.colorHex))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 8)
        .background(WaypointsColors.sandLight)
    }
    
    private var filteredPlaces: [Place] {
        places.filter { place in
            // Search query filter
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch = place.name.lowercased().contains(query) ||
                    place.country.lowercased().contains(query) ||
                    place.note.lowercased().contains(query)
            }
            
            // Status filter
            let matchesStatus: Bool
            switch selectedFilter {
            case .all: matchesStatus = true
            case .favorites: matchesStatus = place.isFavorite
            case .visited: matchesStatus = place.isVisited
            case .unvisited: matchesStatus = !place.isVisited
            }
            
            // Collection filter
            let matchesCollection: Bool
            if let colId = selectedCollectionId {
                matchesCollection = place.collections.contains(where: { $0.id == colId })
            } else {
                matchesCollection = true
            }
            
            return matchesSearch && matchesStatus && matchesCollection
        }
    }
    
    private func placeRow(_ place: Place) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WaypointsColors.deepForest)
                    
                    if place.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(WaypointsColors.sunsetAmber)
                    }
                    
                    if place.isVisited {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
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
                .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundStyle(WaypointsColors.deepForest.opacity(0.3))
            
            Text("No Waypoints Found")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text(searchText.isEmpty ? "Pin locations on the 3D globe or identify discoveries to create your waypoints." : "No results matching '\(searchText)'.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if searchText.isEmpty {
                Button {
                    showingAddPlaceSheet = true
                } label: {
                    Label("Add Manual Waypoint", systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(WaypointsColors.deepForest)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }
}

public struct AddManualPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionModel.name) private var collections: [CollectionModel]
    
    @State private var name = ""
    @State private var country = ""
    @State private var latitudeString = ""
    @State private var longitudeString = ""
    @State private var note = ""
    @State private var isFavorite = false
    @State private var isVisited = false
    @State private var selectedCollectionIds: Set<String> = []
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Place Details") {
                    TextField("Place name (e.g. Lake Como)", text: $name)
                    TextField("Country / Region (e.g. Italy)", text: $country)
                }
                
                Section("Coordinates") {
                    HStack {
                        Text("Latitude")
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("e.g. 45.9867", text: $latitudeString)
                            .keyboardType(.numbersAndPunctuation)
                    }
                    HStack {
                        Text("Longitude")
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("e.g. 9.2561", text: $longitudeString)
                            .keyboardType(.numbersAndPunctuation)
                    }
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
                
                Section("Status") {
                    Toggle("Mark as Favorite", isOn: $isFavorite)
                    Toggle("Mark as Visited", isOn: $isVisited)
                }
                
                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Waypoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { createPlace() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createPlace() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a place name."
            return
        }
        
        let valResult = CoordinateValidator.validateString(latitude: latitudeString, longitude: longitudeString)
        guard valResult.isValid, let lat = valResult.latitude, let lon = valResult.longitude else {
            errorMessage = valResult.errorMessage ?? "Invalid coordinates entered."
            return
        }
        
        let newPlace = Place(
            name: trimmedName,
            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: lat,
            longitude: lon,
            precision: "exact",
            provenance: .userEntry,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            isFavorite: isFavorite,
            isVisited: isVisited,
            source: "Manual entry",
            evidence: "Manually created by user"
        )
        
        newPlace.collections = collections.filter { selectedCollectionIds.contains($0.id) }
        
        modelContext.insert(newPlace)
        try? modelContext.save()
        dismiss()
    }
}
