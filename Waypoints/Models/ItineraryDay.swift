import Foundation
import SwiftData

@Model
public final class ItineraryDay {
    @Attribute(.unique) public var id: String
    public var dayNumber: Int
    public var title: String
    public var date: Date?
    public var notes: String
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(inverse: \Trip.days)
    public var trip: Trip?
    
    @Relationship(deleteRule: .cascade)
    public var stops: [ItineraryStop] = []
    
    public init(
        id: String = UUID().uuidString,
        dayNumber: Int = 1,
        title: String = "Day 1",
        date: Date? = nil,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.title = title
        self.date = date
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.stops = []
    }
    
    public var sortedStops: [ItineraryStop] {
        stops.sorted { $0.sortOrder < $1.sortOrder }
    }
}
