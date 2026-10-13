import Foundation
import SwiftData

@Model
public final class ItineraryStop {
    @Attribute(.unique) public var id: String
    public var sortOrder: Int
    public var placeName: String
    public var notes: String
    public var scheduledTime: String
    public var isCompleted: Bool
    public var latitude: Double
    public var longitude: Double
    public var placeId: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(inverse: \ItineraryDay.stops)
    public var day: ItineraryDay?
    
    public init(
        id: String = UUID().uuidString,
        sortOrder: Int = 0,
        placeName: String,
        notes: String = "",
        scheduledTime: String = "",
        isCompleted: Bool = false,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        placeId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sortOrder = sortOrder
        self.placeName = placeName
        self.notes = notes
        self.scheduledTime = scheduledTime
        self.isCompleted = isCompleted
        self.latitude = latitude
        self.longitude = longitude
        self.placeId = placeId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
