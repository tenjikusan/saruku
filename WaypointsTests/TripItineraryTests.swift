import XCTest
@testable import Waypoints

final class TripItineraryTests: XCTestCase {
    
    func testTripDurationCalculation() {
        let calendar = Calendar.current
        let start = Date()
        let end = calendar.date(byAdding: .day, value: 5, to: start)!
        
        let trip = Trip(
            name: "Summer Expedition",
            destination: "Switzerland",
            startDate: start,
            endDate: end
        )
        
        XCTAssertEqual(trip.durationInDays, 6)
    }
    
    func testItineraryStopsSortingAndCompletion() {
        let day = ItineraryDay(dayNumber: 1, title: "Tokyo Day 1")
        
        let stop1 = ItineraryStop(sortOrder: 2, placeName: "Senso-ji", isCompleted: false)
        let stop2 = ItineraryStop(sortOrder: 1, placeName: "Tokyo Skytree", isCompleted: false)
        let stop3 = ItineraryStop(sortOrder: 3, placeName: "Akihabara", isCompleted: true)
        
        day.stops = [stop1, stop2, stop3]
        
        let sorted = day.sortedStops
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].placeName, "Tokyo Skytree")
        XCTAssertEqual(sorted[1].placeName, "Senso-ji")
        XCTAssertEqual(sorted[2].placeName, "Akihabara")
        XCTAssertTrue(sorted[2].isCompleted)
    }
    
    func testConsecutiveStopsHaversineDistance() {
        // Shibuya (35.6580, 139.7016) to Shinjuku (35.6938, 139.7034)
        let distKm = CoordinateMath.haversineDistanceKm(
            lat1: 35.6580, lon1: 139.7016,
            lat2: 35.6938, lon2: 139.7034
        )
        
        // Expected ~3.9 - 4.1 km
        XCTAssertGreaterThan(distKm, 3.5)
        XCTAssertLessThan(distKm, 4.5)
    }
}
