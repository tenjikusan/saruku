import Foundation
import SwiftData

@Model
public final class JournalEntry {
    @Attribute(.unique) public var id: String
    public var title: String
    public var note: String
    public var visitDate: Date
    public var rating: Int
    public var imageFileNamesJSON: String?
    public var tripId: String?
    public var placeId: String?
    public var placeName: String
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(inverse: \Place.journalEntries)
    public var place: Place?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        note: String = "",
        visitDate: Date = Date(),
        rating: Int = 5,
        imageFileNames: [String] = [],
        tripId: String? = nil,
        placeId: String? = nil,
        placeName: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.visitDate = visitDate
        self.rating = min(max(rating, 1), 5)
        self.tripId = tripId
        self.placeId = placeId
        self.placeName = placeName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageFileNames = imageFileNames
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
}
