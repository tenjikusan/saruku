import SwiftUI
import SwiftData

public struct UnifiedSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [Place]
    @Query private var trips: [Trip]
    @Query private var collections: [CollectionModel]
    @Query private var discoveries: [Discovery]
    
    @State private var query = ""
    @State private var searchScope: SearchScope = .myWaypoints
    
    // Filters
    @State private var filterOnlyFavorites = false
    @State private var filterOnlyVisited = false
    @State private var selectedCollectionId: String? = nil
    @State private var selectedCountry: String? = nil
    @State private var showingFilterSheet = false
    
    // World search state
    @State private var worldResults: [LocationCandidate] = []
    @State private var isSearchingWorld = false
    @State private var worldSearchError: String? = nil
    @State private var candidateToSave: LocationCandidate? = nil
    
    public enum SearchScope: String, CaseIterable, Identifiable {
        case myWaypoints = "Search My Waypoints"
        case theWorld = "Search the World (OSM)"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    private var uniqueCountries: [String] {
        let list = places.map { $0.country.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return Array(Set(list)).sorted()
    }
    
    private var filteredPlaces: [Place] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return places.filter { p in
            // Query match
            let matchesQuery: Bool
            if q.isEmpty {
                matchesQuery = true
            } else {
                matchesQuery = p.name.lowercased().contains(q) ||
                    p.city.lowercased().contains(q) ||
                    p.region.lowercased().contains(q) ||
                    p.country.lowercased().contains(q) ||
                    p.note.lowercased().contains(q) ||
                    p.category.lowercased().contains(q)
            }
            
            // Status filters
            if filterOnlyFavorites && !p.isFavorite { return false }
            if filterOnlyVisited && !p.isVisited { return false }
            
            // Collection filter
            if let colId = selectedCollectionId, !p.collections.contains(where: { $0.id == colId }) {
                return false
            }
            
            // Country filter
            if let country = selectedCountry, p.country.lowercased() != country.lowercased() {
                return false
            }
            
            return matchesQuery
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scope Picker
                Picker("Scope", selection: $searchScope) {
                    ForEach(SearchScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(WaypointsColors.sandLight)
                
                // Active Filters Chips (for local search)
                if searchScope == .myWaypoints {
                    activeFiltersBar
                }
                
                // Results Content
                if searchScope == .myWaypoints {
                    localResultsList
                } else {
                    worldResultsList
                }
            }
            .searchable(text: $query, prompt: searchScope == .myWaypoints ? "Search places, cities, notes…" : "Search world cities, landmarks…")
            .onSubmit(of: .search) {
                if searchScope == .theWorld {
                    executeWorldSearch()
                }
            }
            .navigationTitle("Search")
            .toolbar {
                if searchScope == .myWaypoints {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingFilterSheet = true
                        } label: {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundStyle(WaypointsColors.deepForest)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                SearchFilterSheet(
                    onlyFavorites: $filterOnlyFavorites,
                    onlyVisited: $filterOnlyVisited,
                    selectedCollectionId: $selectedCollectionId,
                    selectedCountry: $selectedCountry,
                    collections: collections,
                    countries: uniqueCountries
                )
            }
            .sheet(item: $candidateToSave) { cand in
                SaveCandidateSheet(candidate: cand, collections: collections)
            }
        }
    }
    
    // MARK: - Active Filters Bar
    
    private var hasActiveFilters: Bool {
        filterOnlyFavorites || filterOnlyVisited || selectedCollectionId != nil || selectedCountry != nil
    }
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if hasActiveFilters {
                    Button {
                        filterOnlyFavorites = false
                        filterOnlyVisited = false
                        selectedCollectionId = nil
                        selectedCountry = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Reset Filters")
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                    }
                }
                
                if filterOnlyFavorites {
                    filterPill(label: "Favorites", onRemove: { filterOnlyFavorites = false })
                }
                if filterOnlyVisited {
                    filterPill(label: "Visited", onRemove: { filterOnlyVisited = false })
                }
                if let colId = selectedCollectionId, let col = collections.first(where: { $0.id == colId }) {
                    filterPill(label: col.name, onRemove: { selectedCollectionId = nil })
                }
                if let country = selectedCountry {
                    filterPill(label: country, onRemove: { selectedCountry = nil })
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .background(WaypointsColors.sandLight)
    }
    
    private func filterPill(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(WaypointsColors.deepForest)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
    
    // MARK: - Local Results List
    
    private var localResultsList: some View {
        Group {
            if filteredPlaces.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("No Matching Saved Waypoints")
                        .font(.headline)
                        .foregroundStyle(WaypointsColors.deepForest)
                    Text("Try adjusting your query or resetting your active search filters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredPlaces) { place in
                        NavigationLink {
                            PlaceDetailView(place: place)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(place.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(WaypointsColors.deepForest)
                                    if place.isFavorite {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundStyle(WaypointsColors.sunsetAmber)
                                    }
                                }
                                
                                let loc = [place.city, place.country].filter { !$0.isEmpty }.joined(separator: ", ")
                                if !loc.isEmpty {
                                    Text(loc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text(place.formattedCoordinates)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    // MARK: - World Results List
    
    private var worldResultsList: some View {
        Group {
            if isSearchingWorld {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                    Text("Searching worldwide geographic index (Photon OSM)…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else if worldResults.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(WaypointsColors.deepForest.opacity(0.3))
                    Text("Search the World")
                        .font(.headline)
                        .foregroundStyle(WaypointsColors.deepForest)
                    Text("Type any global city, beach, or landmark to search live OpenStreetMap data.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button("Search now for \"\(query)\"") {
                            executeWorldSearch()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(WaypointsColors.deepForest)
                        .padding(.top, 4)
                    }
                    Spacer()
                }
            } else {
                List {
                    ForEach(worldResults) { cand in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cand.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(WaypointsColors.deepForest)
                                
                                Text(cand.country)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(cand.formattedCoordinates)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                candidateToSave = cand
                            } label: {
                                Text("Save Pin")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(WaypointsColors.deepForest)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private func executeWorldSearch() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        
        isSearchingWorld = true
        worldSearchError = nil
        Task {
            let results = await GeocodingEngine.shared.search(query: q)
            await MainActor.run {
                worldResults = results
                isSearchingWorld = false
            }
        }
    }
}

// MARK: - Filter Sheet

struct SearchFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var onlyFavorites: Bool
    @Binding var onlyVisited: Bool
    @Binding var selectedCollectionId: String?
    @Binding var selectedCountry: String?
    
    let collections: [CollectionModel]
    let countries: [String]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Toggle("Only Favorites ⭐", isOn: $onlyFavorites)
                    Toggle("Only Visited 📍", isOn: $onlyVisited)
                }
                
                if !collections.isEmpty {
                    Section("Collection") {
                        Picker("Select Collection", selection: $selectedCollectionId) {
                            Text("All Collections").tag(nil as String?)
                            ForEach(collections) { col in
                                Text(col.name).tag(col.id as String?)
                            }
                        }
                    }
                }
                
                if !countries.isEmpty {
                    Section("Country / Region") {
                        Picker("Select Country", selection: $selectedCountry) {
                            Text("All Countries").tag(nil as String?)
                            ForEach(countries, id: \.self) { c in
                                Text(c).tag(c as String?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Waypoints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Save Candidate Sheet

struct SaveCandidateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let candidate: LocationCandidate
    let collections: [CollectionModel]
    
    @State private var name: String
    @State private var country: String
    @State private var selectedCollectionId: String? = nil
    
    init(candidate: LocationCandidate, collections: [CollectionModel]) {
        self.candidate = candidate
        self.collections = collections
        _name = State(initialValue: candidate.name)
        _country = State(initialValue: candidate.country)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Waypoint Details") {
                    TextField("Name", text: $name)
                    TextField("Country / Region", text: $country)
                    Text("Coordinates: \(candidate.formattedCoordinates)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !collections.isEmpty {
                    Section("Collection") {
                        Picker("Assign Collection", selection: $selectedCollectionId) {
                            Text("None").tag(nil as String?)
                            ForEach(collections) { c in
                                Text(c.name).tag(c.id as String?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Save Waypoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let place = Place(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
                            latitude: candidate.latitude,
                            longitude: candidate.longitude,
                            precision: candidate.precision,
                            provenance: .geocodedResult,
                            source: "World Search",
                            evidence: "Saved from worldwide location search"
                        )
                        if let selectedCollectionId, let found = collections.first(where: { $0.id == selectedCollectionId }) {
                            place.collections.append(found)
                        }
                        modelContext.insert(place)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
