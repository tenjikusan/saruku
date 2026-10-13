import Foundation
import SwiftData

@Model
public final class Trip {
    @Attribute(.unique) public var id: String
    public var name: String
    public var destination: String
    public var startDate: Date
    public var endDate: Date
    public var tripDescription: String
    public var coverImageFileName: String?
    public var colorHex: String
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    public var days: [ItineraryDay] = []
    
    @Relationship(deleteRule: .nullify)
    public var places: [Place] = []
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        destination: String = "",
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        tripDescription: String = "",
        coverImageFileName: String? = nil,
        colorHex: String = "#244B3B",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.tripDescription = tripDescription
        self.coverImageFileName = coverImageFileName
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.days = []
        self.places = []
    }
    
    public var sortedDays: [ItineraryDay] {
        days.sorted { $0.dayNumber < $1.dayNumber }
    }
    
    public var durationInDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(1, (components.day ?? 0) + 1)
    }
}
