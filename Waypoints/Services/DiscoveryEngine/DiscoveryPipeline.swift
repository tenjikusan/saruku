import Foundation

/// Unified 10-step discovery processing and location resolution pipeline.
public final class DiscoveryPipeline: @unchecked Sendable {
    public static let shared = DiscoveryPipeline()
    
    private let geocodingEngine: GeocodingEngine
    private let socialMetadata: SocialMetadataService
    private let naturalLanguage: NaturalLanguageService
    private let visionOCR: VisionOCRService
    
    public init(
        geocodingEngine: GeocodingEngine = .shared,
        socialMetadata: SocialMetadataService = SocialMetadataService(),
        naturalLanguage: NaturalLanguageService = .shared,
        visionOCR: VisionOCRService = .shared
    ) {
        self.geocodingEngine = geocodingEngine
        self.socialMetadata = socialMetadata
        self.naturalLanguage = naturalLanguage
        self.visionOCR = visionOCR
    }
    
    // MARK: - Pipeline Execution
    
    public func identifyLocation(for discovery: Discovery) async -> Discovery {
        discovery.status = .findingLocation
        discovery.statusMessage = "Analyzing discovery for location clues…"
        
        var evidence: [String] = []
        var candidates: [LocationCandidate] = []
        
        // Step 1: Direct coordinates from URL
        if !discovery.originalURL.isEmpty,
           let urlResult = LinkExtractor.extractCoordinates(from: discovery.originalURL) {
            evidence.append(urlResult.evidence)
            let isApprox = urlResult.precision == "approximate"
            let candidate = LocationCandidate(
                name: !discovery.caption.isEmpty ? String(discovery.caption.prefix(40)) : (isApprox ? "Map viewing area" : "Location from link"),
                country: String(format: "Coordinates (%.4f, %.4f)", urlResult.latitude, urlResult.longitude),
                latitude: urlResult.latitude,
                longitude: urlResult.longitude,
                precision: urlResult.precision,
                source: urlResult.source,
                attribution: "Verified Map Link",
                evidence: urlResult.evidence,
                provenance: urlResult.provenance,
                requiresConfirmation: urlResult.requiresConfirmation,
                isDemo: false
            )
            candidates.append(candidate)
        }
        
        // Step 2: Direct coordinates from caption text
        if candidates.isEmpty && !discovery.caption.isEmpty,
           let textResult = LinkExtractor.extractCoordinates(fromText: discovery.caption) {
            evidence.append(textResult.evidence)
            let candidate = LocationCandidate(
                name: String(discovery.caption.components(separatedBy: CharacterSet(charactersIn: ",;\n")).first?.prefix(40) ?? "Extracted Coordinates"),
                country: String(format: "Coordinates (%.4f, %.4f)", textResult.latitude, textResult.longitude),
                latitude: textResult.latitude,
                longitude: textResult.longitude,
                precision: textResult.precision,
                source: textResult.source,
                attribution: "User Caption Text",
                evidence: textResult.evidence,
                provenance: textResult.provenance,
                requiresConfirmation: false,
                isDemo: false
            )
            candidates.append(candidate)
        }
        
        // If direct coordinates were found, transition immediately to confirmation
        if !candidates.isEmpty {
            discovery.candidates = candidates
            discovery.selectedCandidate = candidates.first
            discovery.evidence = evidence
            discovery.status = .needsConfirmation
            
            let isApprox = candidates.first?.precision == "approximate"
            discovery.statusMessage = isApprox
                ? "Found map viewing-centre coordinates (approximate). Please review and confirm your pin position."
                : "Found \(candidates.count) location candidate(s). Please confirm your pin."
            return discovery
        }
        
        // Step 3: Extract place name clues from URL & caption
        var clues = LinkExtractor.extractPlaceNameCandidates(url: discovery.originalURL, caption: discovery.caption)
        
        // Step 4: Extract entities via Apple NaturalLanguage
        if !discovery.caption.isEmpty {
            let nlClues = naturalLanguage.extractLocationEntities(from: discovery.caption)
            for clue in nlClues {
                if !clues.contains(where: { $0.name.lowercased() == clue.name.lowercased() }) {
                    clues.append(clue)
                }
            }
        }
        
        // Step 5: Check social metadata for accessible public links or platform notices
        var socialNotice: String? = nil
        if clues.isEmpty && !discovery.originalURL.isEmpty {
            let meta = await socialMetadata.fetchMetadata(for: discovery.originalURL)
            if meta.isAccessible {
                clues.append(contentsOf: meta.clues)
                if let ev = meta.evidence { evidence.append(ev) }
                if let title = meta.title, discovery.caption.isEmpty {
                    discovery.caption = title
                }
            } else if let notice = meta.notice {
                socialNotice = notice
            }
        }
        
        // Step 6: Search places via GeocodingEngine
        if !clues.isEmpty {
            evidence.append("Found \(clues.count) place clue(s): " + clues.map { "\"\($0.name)\"" }.joined(separator: ", "))
            
            for clue in clues.prefix(3) {
                let matches = await geocodingEngine.search(query: clue.name)
                for m in matches {
                    if !candidates.contains(where: { abs($0.latitude - m.latitude) < 0.0001 && abs($0.longitude - m.longitude) < 0.0001 }) {
                        candidates.append(m)
                    }
                }
            }
        }
        
        if !candidates.isEmpty {
            discovery.candidates = candidates
            discovery.selectedCandidate = candidates.first
            discovery.evidence = evidence
            discovery.status = .needsConfirmation
            discovery.statusMessage = "Found \(candidates.count) location candidate(s). Please review and confirm your pin."
            return discovery
        }
        
        // Step 7: Inaccessible / No clues found
        let fallbackMsg = socialNotice ?? "The app does not fetch social post captions or private webpage contents. Please paste a caption, place name, or coordinates, or pick manually on the globe."
        discovery.candidates = []
        discovery.selectedCandidate = nil
        discovery.status = .needsInfo
        discovery.statusMessage = fallbackMsg
        evidence.append(socialNotice != nil ? "Notice: \(socialNotice!)" : "No coordinates found in link; external social media content was not scraped")
        discovery.evidence = evidence
        
        return discovery
    }
    
    // MARK: - Place Conversion
    
    public func convertDiscoveryToPlace(
        discovery: Discovery,
        candidate: LocationCandidate?,
        overrideName: String? = nil,
        overrideCountry: String? = nil,
        overrideLat: Double? = nil,
        overrideLon: Double? = nil,
        overrideProvenance: CoordinateProvenance? = nil
    ) throws -> Place {
        let chosen = candidate ?? discovery.selectedCandidate
        
        let rawLat = overrideLat ?? chosen?.latitude
        let rawLon = overrideLon ?? chosen?.longitude
        
        guard let lat = rawLat, let lon = rawLon,
              CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) else {
            throw PipelineError.invalidCoordinates("Valid coordinates (-90 to 90 lat, -180 to 180 lon) are required before pinning to the globe.")
        }
        
        let rawName = overrideName ?? chosen?.name ?? discovery.caption
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw PipelineError.missingName("A valid place name is required before pinning to the globe.")
        }
        
        let country = (overrideCountry ?? chosen?.country ?? "Location saved").trimmingCharacters(in: .whitespacesAndNewlines)
        let provenance = overrideProvenance ?? chosen?.provenance ?? .userEntry
        
        // Derive stable place ID from discovery ID so retries are strictly idempotent
        let stableId = discovery.confirmedPlaceId ?? ("place_" + discovery.id)
        let themes = ["lake", "temple", "desert"]
        let randomTheme = themes.randomElement() ?? "lake"
        
        let place = Place(
            id: stableId,
            name: name,
            country: country,
            latitude: lat,
            longitude: lon,
            precision: chosen?.precision ?? "exact",
            provenance: provenance,
            sourceURL: !discovery.originalURL.isEmpty ? discovery.originalURL : nil,
            note: discovery.caption,
            isFavorite: false,
            isVisited: false,
            theme: randomTheme,
            source: chosen?.source ?? "Manual pin",
            evidence: chosen?.evidence ?? "Confirmed by user",
            discoveryId: discovery.id
        )
        
        discovery.status = .locationConfirmed
        discovery.confirmedPlaceId = place.id
        
        return place
    }
}

public enum PipelineError: LocalizedError {
    case invalidCoordinates(String)
    case missingName(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCoordinates(let msg): return msg
        case .missingName(let msg): return msg
        }
    }
}
