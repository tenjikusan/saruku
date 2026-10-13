import Foundation
import SwiftData

/// Unified discovery processing and location resolution pipeline supporting single,
/// multi-location candidate extraction, image OCR, EXIF GPS tags, and batch processing.
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
        
        // Step 3: Check attached images for embedded EXIF GPS tags
        for imageFileName in discovery.imageFileNames {
            let fileURL = LocalMediaStorage.shared.absoluteURL(for: imageFileName)
            if let photoGPS = ImageMetadataExtractor.extractGPSCoordinates(from: fileURL) {
                let namePrefix = !discovery.caption.isEmpty ? String(discovery.caption.prefix(35)) : "Photo Location"
                evidence.append("Extracted embedded EXIF GPS tags from photo \"\(imageFileName)\"")
                let candidate = LocationCandidate(
                    name: namePrefix,
                    country: String(format: "Photo GPS (%.4f, %.4f)", photoGPS.latitude, photoGPS.longitude),
                    latitude: photoGPS.latitude,
                    longitude: photoGPS.longitude,
                    precision: "exact",
                    source: "Photo EXIF Metadata",
                    attribution: "Photograph Metadata",
                    evidence: "Found GPS coordinates embedded in photograph metadata",
                    provenance: .userEntry,
                    requiresConfirmation: false,
                    isDemo: false
                )
                candidates.append(candidate)
                break
            }
        }
        
        // If exact coordinates were found from link, text, or EXIF, transition to confirmation
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
        
        // Step 4: Extract place name clues from URL & caption
        var clues = LinkExtractor.extractPlaceNameCandidates(url: discovery.originalURL, caption: discovery.caption)
        
        // Step 5: Extract entities via Apple NaturalLanguage
        if !discovery.caption.isEmpty {
            let nlClues = naturalLanguage.extractLocationEntities(from: discovery.caption)
            for clue in nlClues {
                if !clues.contains(where: { $0.name.lowercased() == clue.name.lowercased() }) {
                    clues.append(clue)
                }
            }
        }
        
        // Step 6: If discovery has an image and no clues yet, run Apple Vision OCR on the image
        if clues.isEmpty && !discovery.imageFileNames.isEmpty {
            for imageFileName in discovery.imageFileNames {
                if let uiImage = LocalMediaStorage.shared.loadImage(fileName: imageFileName) {
                    let ocrResult = await visionOCR.recognizeText(in: uiImage)
                    if !ocrResult.recognizedText.isEmpty {
                        evidence.append("Extracted text via Apple Vision OCR from image \"\(imageFileName)\"")
                        let ocrClues = naturalLanguage.extractLocationEntities(from: ocrResult.recognizedText)
                        for clue in ocrClues {
                            if !clues.contains(where: { $0.name.lowercased() == clue.name.lowercased() }) {
                                clues.append(clue)
                            }
                        }
                    }
                }
            }
        }
        
        // Step 7: Check social metadata for accessible public links or platform notices
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
        
        // Step 8: Search places via GeocodingEngine (searches up to 8 distinct clues)
        if !clues.isEmpty {
            evidence.append("Found \(clues.count) place clue(s): " + clues.map { "\"\($0.name)\"" }.joined(separator: ", "))
            
            for clue in clues.prefix(8) {
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
        
        // Step 9: Inaccessible / No clues found
        let fallbackMsg = socialNotice ?? "The app does not fetch social post captions or private webpage contents. Please paste a caption, place name, or coordinates, or pick manually on the globe."
        discovery.candidates = []
        discovery.selectedCandidate = nil
        discovery.status = .needsInfo
        discovery.statusMessage = fallbackMsg
        evidence.append(socialNotice != nil ? "Notice: \(socialNotice!)" : "No coordinates found in link; external social media content was not scraped")
        discovery.evidence = evidence
        
        return discovery
    }
    
    // MARK: - Process and Save in Context
    
    @MainActor
    public func processDiscovery(discovery: Discovery, context: ModelContext) async {
        let updated = await identifyLocation(for: discovery)
        try? context.save()
    }
    
    // MARK: - Multi-Location Confirmation to Places
    
    @MainActor
    public func convertCandidatesToPlaces(
        discovery: Discovery,
        candidates: [LocationCandidate],
        targetCollection: CollectionModel? = nil
    ) -> [Place] {
        var createdPlaces: [Place] = []
        
        for (index, candidate) in candidates.enumerated() {
            // Stable ID per candidate to guarantee idempotent retries
            let stableId = "place_\(discovery.id)_\(index)"
            
            let sourceRef = !discovery.originalURL.isEmpty
                ? [SourceReference(url: discovery.originalURL, platformName: "Discovery", title: discovery.caption)]
                : []
            
            let place = Place(
                id: stableId,
                name: candidate.name,
                country: candidate.country,
                latitude: candidate.latitude,
                longitude: candidate.longitude,
                precision: candidate.precision,
                provenance: candidate.provenance,
                sourceURL: !discovery.originalURL.isEmpty ? discovery.originalURL : nil,
                note: discovery.caption,
                isFavorite: false,
                isVisited: false,
                source: candidate.source,
                evidence: candidate.evidence,
                discoveryId: discovery.id,
                imageFileNames: discovery.imageFileNames,
                sourceReferences: sourceRef
            )
            
            if let col = targetCollection {
                place.collections.append(col)
            }
            
            createdPlaces.append(place)
        }
        
        discovery.status = .locationConfirmed
        if let first = createdPlaces.first {
            discovery.confirmedPlaceId = first.id
        }
        
        return createdPlaces
    }
    
    // MARK: - Single Place Conversion (Backwards Compatible)
    
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
        
        let stableId = discovery.confirmedPlaceId ?? ("place_" + discovery.id)
        
        let sourceRef = !discovery.originalURL.isEmpty
            ? [SourceReference(url: discovery.originalURL, platformName: "Discovery", title: discovery.caption)]
            : []
        
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
            source: chosen?.source ?? "Manual pin",
            evidence: chosen?.evidence ?? "Confirmed by user",
            discoveryId: discovery.id,
            imageFileNames: discovery.imageFileNames,
            sourceReferences: sourceRef
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
