import Foundation

/// Commercial OpenStreetMap geocoding provider adapter (LocationIQ).
/// Requires user-supplied API key in Settings.
public final class LocationIQGeocodingService: GeocodingService, @unchecked Sendable {
    public let name = "LocationIQ (OSM)"
    public let attribution = "© OpenStreetMap contributors, LocationIQ"
    public var isEnabled: Bool
    public var apiKey: String
    
    private let session: URLSession
    
    public init(apiKey: String = "", isEnabled: Bool = false, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.isEnabled = isEnabled && !apiKey.isEmpty
        self.session = session
    }
    
    public func searchPlaces(query: String) async throws -> [LocationCandidate] {
        guard isEnabled, !apiKey.isEmpty else { return [] }
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://us1.locationiq.com/v1/search.php?key=\(apiKey)&q=\(encoded)&format=json&limit=5") else {
            return []
        }
        
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        struct LocationIQItem: Decodable {
            let place_id: String?
            let display_name: String?
            let lat: String
            let lon: String
            let `type`: String?
        }
        
        let items = try JSONDecoder().decode([LocationIQItem].self, from: data)
        return items.compactMap { item in
            guard let lat = Double(item.lat),
                  let lon = Double(item.lon),
                  CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) else {
                return nil
            }
            
            let displayName = item.display_name ?? trimmed
            let placeName = displayName.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? trimmed
            let isArea = ["city", "state", "country", "administrative"].contains(item.type ?? "")
            
            return LocationCandidate(
                name: placeName,
                country: displayName,
                latitude: lat,
                longitude: lon,
                precision: isArea ? "area" : "exact",
                source: "LocationIQ",
                attribution: self.attribution,
                evidence: "Resolved \"\(trimmed)\" via LocationIQ search",
                provenance: .geocodedResult,
                requiresConfirmation: isArea,
                isDemo: false
            )
        }
    }
}
