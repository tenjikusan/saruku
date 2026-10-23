import Foundation
import SwiftData

@Model
public final class Place: Identifiable {
    @Attribute(.unique) public var id: String
    public var name: String
    public var city: String
    public var region: String
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
    public var category: String
    public var source: String
    public var evidence: String
    public var discoveryId: String?
    public var imageFileNamesJSON: String?
    public var sourceReferencesJSON: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(inverse: \CollectionModel.places)
    public var collections: [CollectionModel] = []
    
    @Relationship(deleteRule: .cascade)
    public var journalEntries: [JournalEntry] = []
    
    @Relationship(inverse: \Trip.places)
    public var trips: [Trip] = []
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        city: String = "",
        region: String = "",
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
        category: String = "Destination",
        source: String = "Manual pin",
        evidence: String = "Confirmed by user",
        discoveryId: String? = nil,
        imageFileNames: [String] = [],
        sourceReferences: [SourceReference] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.region = region
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
        self.category = category
        self.source = source
        self.evidence = evidence
        self.discoveryId = discoveryId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.collections = []
        self.journalEntries = []
        self.trips = []
        
        self.imageFileNames = imageFileNames
        self.sourceReferences = sourceReferences
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
    
    public var categoryDisplay: String {
        category.isEmpty ? "Destination" : category
    }
    
    public var categoryEmoji: String {
        switch category.lowercased() {
        case "scenic", "nature", "lake": return "🏞️"
        case "temple", "shrine", "historic": return "⛩️"
        case "mountain", "hiking", "park": return "🏔️"
        case "coastal", "beach", "island": return "🏖️"
        case "food", "cafe", "restaurant", "good eats": return "☕"
        case "city", "architecture": return "🏛️"
        default:
            switch theme.lowercased() {
            case "temple": return "⛩️"
            case "desert": return "🏜️"
            case "mountain": return "🏔️"
            default: return "🏞️"
            }
        }
    }
    
    public var primaryCollectionName: String {
        collections.first?.name ?? "Dream trips"
    }
    
    public var imageFileNames: [String] {
        get {
            guard let json = imageFileNamesJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                imageFileNamesJSON = String(data: data, encoding: .utf8)
            } else {
                imageFileNamesJSON = nil
            }
        }
    }
    
    public var photoFileNames: [String] {
        imageFileNames
    }
    
    public var sourceReferences: [SourceReference] {
        get {
            guard let json = sourceReferencesJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([SourceReference].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                sourceReferencesJSON = String(data: data, encoding: .utf8)
            } else {
                sourceReferencesJSON = nil
            }
        }
    }
    
    public func addSourceReference(_ ref: SourceReference) {
        var current = sourceReferences
        if !current.contains(where: { $0.url == ref.url && !ref.url.isEmpty }) {
            current.append(ref)
            sourceReferences = current
        }
    }
    
    public func addImageFileName(_ fileName: String) {
        var current = imageFileNames
        if !current.contains(fileName) {
            current.append(fileName)
            imageFileNames = current
        }
    }
    
    public func removeImageFileName(_ fileName: String) {
        var current = imageFileNames
        current.removeAll(where: { $0 == fileName })
        imageFileNames = current
        LocalMediaStorage.shared.deleteImage(fileName: fileName)
    }
}
