import Foundation
import SwiftData

@Model
public final class Place {
    @Attribute(.unique) public var id: String
    public var name: String
    public var country: String
    public var latitude: Double
    public var longitude: Double
    public var precision: String
    public var provenanceRaw: String
    public var sourceURL: String?
    public var note: String
    public var isFavorite: Bool
    public var isVisited: Bool
    public var theme: String
    public var source: String
    public var evidence: String
    public var discoveryId: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(inverse: \CollectionModel.places)
    public var collections: [CollectionModel] = []
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        country: String = "",
        latitude: Double,
        longitude: Double,
        precision: String = "exact",
        provenance: CoordinateProvenance = .userEntry,
        sourceURL: String? = nil,
        note: String = "",
        isFavorite: Bool = false,
        isVisited: Bool = false,
        theme: String = "lake",
        source: String = "Manual pin",
        evidence: String = "Confirmed by user",
        discoveryId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.precision = precision
        self.provenanceRaw = provenance.rawValue
        self.sourceURL = sourceURL
        self.note = note
        self.isFavorite = isFavorite
        self.isVisited = isVisited
        self.theme = theme
        self.source = source
        self.evidence = evidence
        self.discoveryId = discoveryId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.collections = []
    }
    
    public var provenance: CoordinateProvenance {
        get {
            CoordinateProvenance(rawValue: provenanceRaw) ?? .userEntry
        }
        set {
            provenanceRaw = newValue.rawValue
        }
    }
    
    public var formattedCoordinates: String {
        String(format: "%.4f°, %.4f°", latitude, longitude)
    }
    
    public var primaryCollectionName: String {
        collections.first?.name ?? "Dream trips"
    }
}
