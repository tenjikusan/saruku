import Foundation

/// Live worldwide geocoding provider using OpenStreetMap data via the Photon API (Komoot).
/// License: Open Database License (ODbL). Permitted for permanent storage and custom globe rendering with attribution.
public final class PhotonGeocodingService: GeocodingService, @unchecked Sendable {
    public let name = "Photon (OpenStreetMap)"
    public let attribution = "© OpenStreetMap contributors, Photon by Komoot"
    public var isEnabled: Bool
    
    private let session: URLSession
    private var lastRequestTime: Date = .distantPast
    private let lock = NSLock()
    
    public init(isEnabled: Bool = true, session: URLSession = .shared) {
        self.isEnabled = isEnabled
        self.session = session
    }
    
    public func searchPlaces(query: String) async throws -> [LocationCandidate] {
        guard isEnabled else { return [] }
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        
        // Rate-limiting politeness (at least 300ms between calls)
        lock.lock()
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        let waitTime = max(0.0, 0.3 - elapsed)
        lastRequestTime = Date().addingTimeInterval(waitTime)
        lock.unlock()
        
        if waitTime > 0 {
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://photon.komoot.io/api/?q=\(encoded)&limit=5") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.setValue("Waypoints-Native-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        let geoJSON = try JSONDecoder().decode(PhotonResponse.self, from: data)
        
        return geoJSON.features.compactMap { feature -> LocationCandidate? in
            guard feature.geometry.coordinates.count >= 2 else { return nil }
            let lon = feature.geometry.coordinates[0]
            let lat = feature.geometry.coordinates[1]
            
            guard CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) else {
                return nil
            }
            
            let p = feature.properties
            let isArea = ["country", "state", "city", "town", "village", "county", "district"].contains(p.type ?? "") ||
                         ["boundary", "place"].contains(p.osmKey ?? "")
            
            let parts = [p.city ?? p.town ?? p.district, p.state, p.country].compactMap { $0 }.filter { !$0.isEmpty }
            let regionDesc = parts.joined(separator: ", ")
            
            let placeName = p.name ?? p.city ?? trimmed
            
            return LocationCandidate(
                name: placeName,
                country: regionDesc.isEmpty ? (p.country ?? "Global destination") : regionDesc,
                latitude: lat,
                longitude: lon,
                precision: isArea ? "area" : "exact",
                source: "Photon (OpenStreetMap)",
                attribution: self.attribution,
                evidence: "Resolved \"\(trimmed)\" via live OpenStreetMap geocoding",
                provenance: .geocodedResult,
                requiresConfirmation: isArea,
                isDemo: false
            )
        }
    }
}

// MARK: - Internal Decodable Models

private struct PhotonResponse: Decodable {
    let features: [PhotonFeature]
}

private struct PhotonFeature: Decodable {
    let geometry: PhotonGeometry
    let properties: PhotonProperties
}

private struct PhotonGeometry: Decodable {
    let coordinates: [Double]
}

private struct PhotonProperties: Decodable {
    let name: String?
    let city: String?
    let town: String?
    let district: String?
    let state: String?
    let country: String?
    let type: String?
    let osmKey: String?
    
    enum CodingKeys: String, CodingKey {
        case name, city, town, district, state, country, type
        case osmKey = "osm_key"
    }
}
