import XCTest
@testable import Waypoints

final class GeocodingServiceTests: XCTestCase {
    
    func testOfflineKnowledgeServiceFindsKnownPlaces() async throws {
        let service = OfflineKnowledgeService()
        
        let kyotoResults = try await service.searchPlaces(query: "Kyoto")
        XCTAssertFalse(kyotoResults.isEmpty)
        XCTAssertEqual(kyotoResults.first?.name, "Kyoto")
        XCTAssertEqual(kyotoResults.first?.country, "Japan")
        XCTAssertEqual(kyotoResults.first?.provenance, .demoData)
        XCTAssertTrue(CoordinateValidator.isValidCoordinate(latitude: kyotoResults.first?.latitude ?? 0, longitude: kyotoResults.first?.longitude ?? 0))
        
        let comoResults = try await service.searchPlaces(query: "Lake Como")
        XCTAssertFalse(comoResults.isEmpty)
        XCTAssertEqual(comoResults.first?.country, "Italy")
    }
    
    func testOfflineKnowledgeServiceIgnoresShortQueries() async throws {
        let service = OfflineKnowledgeService()
        let short = try await service.searchPlaces(query: "a")
        XCTAssertTrue(short.isEmpty)
    }
    
    func testGeocodingEngineCaching() async {
        let offline = OfflineKnowledgeService()
        let engine = GeocodingEngine(
            primaryProvider: offline,
            secondaryProvider: nil,
            offlineProvider: offline,
            allowOfflineFallback: true
        )
        
        // First search
        let res1 = await engine.search(query: "Tokyo")
        XCTAssertFalse(res1.isEmpty)
        
        // Second search (should be served from cache)
        let res2 = await engine.search(query: "Tokyo")
        XCTAssertEqual(res1.count, res2.count)
        XCTAssertEqual(res1.first?.name, res2.first?.name)
        
        // Clear cache
        engine.clearCache()
        let res3 = await engine.search(query: "Tokyo")
        XCTAssertEqual(res1.first?.name, res3.first?.name)
    }
}
