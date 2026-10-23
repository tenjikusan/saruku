import XCTest
@testable import Waypoints

final class WaypointsTests: XCTestCase {
    
    func testPlaceModelInitialization() {
        let place = Place(
            name: "Kyoto",
            city: "Kyoto",
            country: "Japan",
            latitude: 35.0116,
            longitude: 135.7681,
            precision: "area",
            provenance: .userEntry,
            category: "Historic"
        )
        
        XCTAssertEqual(place.name, "Kyoto")
        XCTAssertEqual(place.country, "Japan")
        XCTAssertEqual(place.formattedCoordinates, "35.0116°, 135.7681°")
        XCTAssertEqual(place.provenance.displayLabel, "Manual Entry")
        XCTAssertEqual(place.provenance.systemIcon, "hand.tap.fill")
    }
    
    func testDiscoveryStatusLabels() {
        XCTAssertEqual(DiscoveryStatus.savedAwaiting.displayLabel, "Saved, awaiting identification")
        XCTAssertEqual(DiscoveryStatus.needsConfirmation.displayLabel, "Needs confirmation")
        XCTAssertEqual(DiscoveryStatus.locationConfirmed.displayLabel, "Location confirmed")
    }
    
    func testTripDurationCalculation() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 5, to: start)!
        let trip = Trip(name: "Alpine Tour", startDate: start, endDate: end)
        
        XCTAssertEqual(trip.durationInDays, 6)
    }
    
    func testOfflineKnowledgeServiceSearch() async throws {
        let service = OfflineKnowledgeService()
        let results = try await service.searchPlaces(query: "Kyoto")
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains(where: { $0.name.contains("Kyoto") || $0.country.contains("Japan") }))
    }
    
    func testDeepLinkRouterParsing() {
        let globeURL = URL(string: "waypoints://globe")!
        XCTAssertEqual(DeepLinkRouter.parse(url: globeURL), .globe)
        
        let placesURL = URL(string: "waypoints://places")!
        XCTAssertEqual(DeepLinkRouter.parse(url: placesURL), .places)
        
        let discoveriesURL = URL(string: "waypoints://discoveries")!
        XCTAssertEqual(DeepLinkRouter.parse(url: discoveriesURL), .discoveries)
        
        let invalidURL = URL(string: "https://example.com")!
        XCTAssertNil(DeepLinkRouter.parse(url: invalidURL))
    }
}
