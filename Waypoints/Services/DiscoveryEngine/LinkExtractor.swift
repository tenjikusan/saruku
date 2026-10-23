import Foundation

public struct ExtractedCoordinateResult: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let precision: String // "exact" vs "approximate"
    public let source: String
    public let provenance: CoordinateProvenance
    public let requiresConfirmation: Bool
    public let evidence: String
}

public struct PlaceClue: Equatable, Sendable {
    public let name: String
    public let source: String
    public let confidence: String
    public let evidence: String
    public var context: String { evidence }
    
    public init(name: String, source: String = "Natural Language", confidence: String = "medium", evidence: String = "") {
        self.name = name
        self.source = source
        self.confidence = confidence
        self.evidence = evidence
    }
    
    public init(name: String, context: String) {
        self.name = name
        self.source = "Foundation Model"
        self.confidence = "high"
        self.evidence = context
    }
}

public enum LinkExtractor {
    
    // MARK: - Direct Coordinate Extraction from URLs
    
    public static func extractCoordinates(from urlString: String) -> ExtractedCoordinateResult? {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host?.lowercased() else {
            return nil
        }
        
        // 1. Google Maps
        if host.contains("google.") && (url.path.contains("/maps") || host.contains("maps.google")) {
            // A. Prefer exact marker bang parameters (!3d and !4d)
            if let bang3d = matchRegex(pattern: #"!3d(-?\d+(?:\.\d+)?)"#, in: urlString),
               let bang4d = matchRegex(pattern: #"!4d(-?\d+(?:\.\d+)?)"#, in: urlString),
               let lat = Double(bang3d),
               let lon = Double(bang4d),
               CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) {
                return ExtractedCoordinateResult(
                    latitude: lat,
                    longitude: lon,
                    precision: "exact",
                    source: "Google Maps (Marker)",
                    provenance: .verifiedLink,
                    requiresConfirmation: false,
                    evidence: "Extracted exact marker pin (!3d/!4d) from Google Maps link"
                )
            }
            
            // B. Check query parameter ?q=lat,lon
            if let qValue = getQueryParam("q", from: url),
               let coords = parseLatLonPair(qValue) {
                return ExtractedCoordinateResult(
                    latitude: coords.lat,
                    longitude: coords.lon,
                    precision: "exact",
                    source: "Google Maps (Query)",
                    provenance: .verifiedLink,
                    requiresConfirmation: false,
                    evidence: "Extracted marker coordinate parameter from Google Maps link"
                )
            }
            
            // C. Viewport center @lat,lon,zoom (Treat as approximate area)
            if let centerMatch = matchRegex(pattern: #"@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)"#, in: urlString),
               let coords = parseLatLonPair(centerMatch) {
                return ExtractedCoordinateResult(
                    latitude: coords.lat,
                    longitude: coords.lon,
                    precision: "approximate",
                    source: "Google Maps (Viewport Center)",
                    provenance: .verifiedLink,
                    requiresConfirmation: true,
                    evidence: "Extracted map viewport viewing-centre @lat,lon (approximate area)"
                )
            }
        }
        
        // 2. Apple Maps
        if host.contains("apple.com") && url.path.contains("/maps") {
            for param in ["ll", "sll", "q"] {
                if let val = getQueryParam(param, from: url),
                   let coords = parseLatLonPair(val) {
                    return ExtractedCoordinateResult(
                        latitude: coords.lat,
                        longitude: coords.lon,
                        precision: "exact",
                        source: "Apple Maps Link",
                        provenance: .verifiedLink,
                        requiresConfirmation: false,
                        evidence: "Extracted location coordinates (\(param)) from Apple Maps link"
                    )
                }
            }
        }
        
        // 3. OpenStreetMap
        if host.contains("openstreetmap.org") {
            // A. Marker parameters ?mlat=lat&mlon=lon
            if let mlat = getQueryParam("mlat", from: url),
               let mlon = getQueryParam("mlon", from: url),
               let lat = Double(mlat),
               let lon = Double(mlon),
               CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) {
                return ExtractedCoordinateResult(
                    latitude: lat,
                    longitude: lon,
                    precision: "exact",
                    source: "OpenStreetMap Link",
                    provenance: .verifiedLink,
                    requiresConfirmation: false,
                    evidence: "Extracted exact marker from OpenStreetMap link"
                )
            }
            
            // B. Hash viewport #map=zoom/lat/lon
            if let fragment = url.fragment,
               let match = matchRegex(pattern: #"map=\d+/(-?\d+(?:\.\d+)?)/(-?\d+(?:\.\d+)?)"#, in: fragment) {
                let parts = match.replacingOccurrences(of: "map=", with: "").components(separatedBy: "/")
                if parts.count >= 3,
                   let lat = Double(parts[1]),
                   let lon = Double(parts[2]),
                   CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) {
                    return ExtractedCoordinateResult(
                        latitude: lat,
                        longitude: lon,
                        precision: "approximate",
                        source: "OpenStreetMap Viewport",
                        provenance: .verifiedLink,
                        requiresConfirmation: true,
                        evidence: "Extracted viewport centre from OpenStreetMap link"
                    )
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Direct Coordinates from Text
    
    public static func extractCoordinates(fromText text: String) -> ExtractedCoordinateResult? {
        guard !text.isEmpty else { return nil }
        
        let pattern = #"(-?\d{1,2}(?:\.\d+)?)\s*°?\s*,\s*(-?\d{1,3}(?:\.\d+)?)\s*°?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        for m in matches {
            if m.numberOfRanges >= 3 {
                let latStr = nsString.substring(with: m.range(at: 1))
                let lonStr = nsString.substring(with: m.range(at: 2))
                if let lat = Double(latStr),
                   let lon = Double(lonStr),
                   CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) {
                    return ExtractedCoordinateResult(
                        latitude: lat,
                        longitude: lon,
                        precision: "exact",
                        source: "Text Coordinates",
                        provenance: .userEntry,
                        requiresConfirmation: false,
                        evidence: "Extracted coordinates (\(latStr), \(lonStr)) directly from text"
                    )
                }
            }
        }
        return nil
    }
    
    // MARK: - Place Name Clue Extraction
    
    public static func extractPlaceNameCandidates(url urlString: String, caption: String) -> [PlaceClue] {
        var clues: [PlaceClue] = []
        
        // 1. URL Path extraction
        if let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            let host = url.host?.lowercased() ?? ""
            let path = url.path
            
            // Instagram Location URL: /explore/locations/12345/fushimi-inari-taisha/
            if host.contains("instagram.com"),
               let locMatch = matchRegex(pattern: #"/explore/locations/\d+/([^/?#]+)"#, in: urlString) {
                let name = cleanSlug(locMatch)
                if !name.isEmpty {
                    clues.append(PlaceClue(
                        name: name,
                        source: "instagram_location_url",
                        confidence: "high",
                        evidence: "Extracted place name \"\(name)\" from Instagram location URL"
                    ))
                }
            }
            
            // Wikipedia Article URL: /wiki/Fushimi_Inari-taisha
            if (host.contains("wikipedia.org") || host.contains("wikivoyage.org")),
               path.contains("/wiki/") {
                let slug = path.replacingOccurrences(of: "/wiki/", with: "").components(separatedBy: "/").first ?? ""
                let name = cleanSlug(slug)
                if !name.isEmpty && !name.lowercased().hasPrefix("special:") {
                    clues.append(PlaceClue(
                        name: name,
                        source: "wikipedia_article_url",
                        confidence: "high",
                        evidence: "Extracted title \"\(name)\" from Wikipedia article URL"
                    ))
                }
            }
            
            // General Travel blog / destinations slug
            if let destMatch = matchRegex(pattern: #"/(?:destination|destinations|places|travel)/([^/?#]+)"#, in: path) {
                let name = cleanSlug(destMatch)
                if !name.isEmpty && name.count > 3 {
                    clues.append(PlaceClue(
                        name: name,
                        source: "travel_slug_url",
                        confidence: "medium",
                        evidence: "Extracted destination clue from URL path"
                    ))
                }
            }
        }
        
        // 2. Hashtags in caption (e.g. #LakeComo -> "Lake Como")
        if !caption.isEmpty {
            let hashtagRegex = try? NSRegularExpression(pattern: #"#([A-Za-z0-9_]{3,30})"#)
            let nsCaption = caption as NSString
            let matches = hashtagRegex?.matches(in: caption, range: NSRange(location: 0, length: nsCaption.length)) ?? []
            
            for m in matches {
                if m.numberOfRanges >= 2 {
                    let tag = nsCaption.substring(with: m.range(at: 1))
                    let splitTag = splitCamelCase(tag)
                    if splitTag.count >= 4 && !isGenericHashtag(splitTag) {
                        if !clues.contains(where: { $0.name.lowercased() == splitTag.lowercased() }) {
                            clues.append(PlaceClue(
                                name: splitTag,
                                source: "caption_hashtag",
                                confidence: "medium",
                                evidence: "Extracted place clue from hashtag #\(tag)"
                            ))
                        }
                    }
                }
            }
            
            // If caption has a clean title or landmark name
            let firstLine = caption.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespaces) ?? ""
            if !firstLine.isEmpty && firstLine.count < 60 && !firstLine.hasPrefix("http") {
                if !clues.contains(where: { $0.name.lowercased() == firstLine.lowercased() }) {
                    clues.append(PlaceClue(
                        name: firstLine,
                        source: "user_caption",
                        confidence: "medium",
                        evidence: "Extracted location from caption text"
                    ))
                }
            }
        }
        
        return clues
    }
    
    // MARK: - Private Helpers
    
    private static func matchRegex(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsText = text as NSString
        let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length))
        guard let m = match, m.numberOfRanges >= 2 else { return nil }
        return nsText.substring(with: m.range(at: 1))
    }
    
    private static func getQueryParam(_ param: String, from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name.lowercased() == param.lowercased() })?
            .value
    }
    
    private static func parseLatLonPair(_ str: String) -> (lat: Double, lon: Double)? {
        let parts = str.components(separatedBy: ",")
        guard parts.count == 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)),
              CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) else {
            return nil
        }
        return (lat, lon)
    }
    
    private static func cleanSlug(_ str: String) -> String {
        let unescaped = str.removingPercentEncoding ?? str
        return unescaped
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func splitCamelCase(_ str: String) -> String {
        let pattern = #"([a-z])([A-Z])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return str }
        let range = NSRange(location: 0, length: str.utf16.count)
        return regex.stringByReplacingMatches(in: str, range: range, withTemplate: "$1 $2")
    }
    
    private static func isGenericHashtag(_ tag: String) -> Bool {
        let generic = ["travel", "wanderlust", "photooftheday", "instatravel", "nature", "vacation", "trip", "holiday", "beautiful"]
        return generic.contains(tag.lowercased())
    }
}
