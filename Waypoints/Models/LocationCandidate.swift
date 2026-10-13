import Foundation

/// A structured candidate location retrieved from a link, geocoding provider, or OCR analysis.
public struct LocationCandidate: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var country: String
    public var latitude: Double
    public var longitude: Double
    public var precision: String // "exact", "area", "approximate"
    public var source: String
    public var attribution: String
    public var evidence: String
    public var provenance: CoordinateProvenance
    public var requiresConfirmation: Bool
    public var isDemo: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        country: String = "",
        latitude: Double,
        longitude: Double,
        precision: String = "exact",
        source: String = "Geocoding Provider",
        attribution: String = "© OpenStreetMap contributors",
        evidence: String = "",
        provenance: CoordinateProvenance = .geocodedResult,
        requiresConfirmation: Bool = false,
        isDemo: Bool = false
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.precision = precision
        self.source = source
        self.attribution = attribution
        self.evidence = evidence
        self.provenance = provenance
        self.requiresConfirmation = requiresConfirmation
        self.isDemo = isDemo
    }
    
    public var formattedCoordinates: String {
        String(format: "%.4f°, %.4f°", latitude, longitude)
    }
    
    public var isExact: Bool {
        precision.lowercased() == "exact"
    }
}
