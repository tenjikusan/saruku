import SwiftUI

public struct LocationConfirmationSheet: View {
    public let discovery: Discovery
    public var onConfirm: (Place) -> Void
    public var onPickOnGlobeTapped: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    
    @State private var candidates: [LocationCandidate] = []
    @State private var selectedCandidate: LocationCandidate? = nil
    @State private var placeName: String = ""
    @State private var placeCountry: String = ""
    @State private var latitudeText: String = ""
    @State private var longitudeText: String = ""
    @State private var currentProvenance: CoordinateProvenance = .geocodedResult
    
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var searchError: String? = nil
    @State private var validationError: String? = nil
    
    public init(
        discovery: Discovery,
        onConfirm: @escaping (Place) -> Void,
        onPickOnGlobeTapped: @escaping () -> Void
    ) {
        self.discovery = discovery
        self.onConfirm = onConfirm
        self.onPickOnGlobeTapped = onPickOnGlobeTapped
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Status
                    HStack {
                        StatusBadge(status: discovery.status)
                        Spacer()
                    }
                    
                    Text(discovery.statusMessage)
                        .font(WaypointsTypography.body)
                        .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                    
                    // 1. Identification Evidence
                    if !discovery.evidence.isEmpty {
                        CardContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("IDENTIFICATION EVIDENCE")
                                    .font(WaypointsTypography.eyebrow)
                                    .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                                
                                ForEach(discovery.evidence, id: \.self) { ev in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .foregroundColor(Color.waypointsGreen)
                                        Text(ev)
                                            .font(WaypointsTypography.caption)
                                            .foregroundColor(WaypointsTheme.textPrimary(for: scheme))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // 2. Select a Candidate
                    if !candidates.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SELECT A CANDIDATE")
                                .font(WaypointsTypography.eyebrow)
                                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                            
                            ForEach(candidates) { candidate in
                                let isSelected = selectedCandidate?.id == candidate.id
                                Button {
                                    applyCandidate(candidate)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "mappin.circle")
                                            .font(.title3)
                                            .foregroundColor(isSelected ? Color.waypointsGreen : Color.waypointsSage)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(candidate.name)
                                                .font(WaypointsTypography.subheadline)
                                                .foregroundColor(WaypointsTheme.textPrimary(for: scheme))
                                            
                                            Text(candidate.country.isEmpty ? candidate.formattedCoordinates : candidate.country)
                                                .font(WaypointsTypography.caption)
                                                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                                            
                                            HStack(spacing: 6) {
                                                ProvenanceBadge(provenance: candidate.provenance)
                                                if candidate.isExact {
                                                    Text("Exact Pin")
                                                        .font(WaypointsTypography.eyebrow)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.waypointsGreen.opacity(0.1))
                                                        .foregroundColor(Color.waypointsGreen)
                                                        .cornerRadius(6)
                                                }
                                            }
                                            .padding(.top, 2)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(isSelected ? Color.waypointsGreen.opacity(0.08) : WaypointsTheme.surface(for: scheme))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isSelected ? Color.waypointsGreen : WaypointsTheme.cardBorder(for: scheme), lineWidth: isSelected ? 1.5 : 1)
                                    )
                                }
                            }
                        }
                    }
                    
                    // 3. Inline Geocoding Search
                    CardContainer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LOOKUP LOCATION BY NAME")
                                .font(WaypointsTypography.eyebrow)
                                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                            
                            HStack {
                                TextField("Search city, landmark, or temple…", text: $searchQuery)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(WaypointsTheme.background(for: scheme))
                                    .cornerRadius(10)
                                
                                Button {
                                    runSearch()
                                } label: {
                                    HStack(spacing: 4) {
                                        if isSearching {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "magnifyingglass")
                                        }
                                        Text("Search")
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.waypointsGreen)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(isSearching || searchQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            
                            if let searchError {
                                Text(searchError)
                                    .font(WaypointsTypography.caption)
                                    .foregroundColor(Color.red)
                            }
                        }
                    }
                    
                    // 4. Pick Directly on Globe
                    Button {
                        dismiss()
                        onPickOnGlobeTapped()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "globe.americas.fill")
                            Text("Pick position directly on globe 🌐")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.waypointsSage.opacity(0.2))
                        .foregroundColor(Color.waypointsGreen)
                        .cornerRadius(12)
                    }
                    
                    // 5. Confirm / Adjust Place Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CONFIRM / ADJUST PLACE NAME")
                            .font(WaypointsTypography.eyebrow)
                            .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                        
                        TextField("Place Name", text: $placeName)
                            .padding(12)
                            .background(WaypointsTheme.surface(for: scheme))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
                        
                        Text("REGION / COUNTRY")
                            .font(WaypointsTypography.eyebrow)
                            .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                        
                        TextField("Country / Region", text: $placeCountry)
                            .padding(12)
                            .background(WaypointsTheme.surface(for: scheme))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LATITUDE")
                                    .font(WaypointsTypography.eyebrow)
                                    .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                                
                                TextField("-90 to 90", text: $latitudeText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .padding(12)
                                    .background(WaypointsTheme.surface(for: scheme))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LONGITUDE")
                                    .font(WaypointsTypography.eyebrow)
                                    .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                                
                                TextField("-180 to 180", text: $longitudeText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .padding(12)
                                    .background(WaypointsTheme.surface(for: scheme))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
                            }
                        }
                    }
                    
                    if let validationError {
                        Text(validationError)
                            .font(WaypointsTypography.caption)
                            .foregroundColor(Color.red)
                    }
                    
                    // 6. Confirm & Pin Button
                    let isFormValid = isValid()
                    PrimaryButton("Confirm & Pin to Globe 📍", isDisabled: !isFormValid) {
                        confirmAction()
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(WaypointsTheme.background(for: scheme).ignoresSafeArea())
            .navigationTitle("Confirm Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .tint(Color.waypointsGreen)
                }
            }
            .onAppear {
                setupInitialData()
            }
        }
    }
    
    private func setupInitialData() {
        candidates = discovery.candidates
        if let selected = discovery.selectedCandidate ?? discovery.candidates.first {
            applyCandidate(selected)
        } else {
            placeName = discovery.caption
        }
    }
    
    private func applyCandidate(_ c: LocationCandidate) {
        selectedCandidate = c
        placeName = c.name
        placeCountry = c.country
        latitudeText = String(format: "%.4f", c.latitude)
        longitudeText = String(format: "%.4f", c.longitude)
        currentProvenance = c.provenance
        validationError = nil
    }
    
    private func isValid() -> Bool {
        guard !placeName.trimmingCharacters(in: .whitespaces).isEmpty,
              let lat = Double(latitudeText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(longitudeText.trimmingCharacters(in: .whitespaces)),
              CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) else {
            return false
        }
        return true
    }
    
    private func runSearch() {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        
        isSearching = true
        searchError = nil
        
        Task {
            let results = await GeocodingEngine.shared.search(query: q)
            await MainActor.run {
                isSearching = false
                if results.isEmpty {
                    searchError = "No places found for \"\(q)\". Try another city, temple, or landmark name."
                } else {
                    candidates = results + candidates.filter { existing in
                        !results.contains(where: { abs($0.latitude - existing.latitude) < 0.001 && abs($0.longitude - existing.longitude) < 0.001 })
                    }
                    if let first = results.first {
                        applyCandidate(first)
                    }
                }
            }
        }
    }
    
    private func confirmAction() {
        guard let lat = Double(latitudeText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(longitudeText.trimmingCharacters(in: .whitespaces)),
              CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) else {
            validationError = "Please enter valid coordinates (-90 to 90 latitude, -180 to 180 longitude)."
            return
        }
        
        let trimmedName = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationError = "A place name is required before pinning."
            return
        }
        
        do {
            let place = try DiscoveryPipeline.shared.convertDiscoveryToPlace(
                discovery: discovery,
                candidate: selectedCandidate,
                overrideName: trimmedName,
                overrideCountry: placeCountry,
                overrideLat: lat,
                overrideLon: lon,
                overrideProvenance: currentProvenance
            )
            onConfirm(place)
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }
    }
}
