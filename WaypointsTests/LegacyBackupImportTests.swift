import XCTest
import SwiftData
@testable import Waypoints

@MainActor
final class LegacyBackupImportTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([Place.self, Discovery.self, CollectionModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
    }
    
    func testLegacyBackupImportWithValidAndInvalidRecords() throws {
        let jsonString = """
        {
            "version": "vaypoints.backup.v1",
            "exportedAt": "2026-10-13T12:00:00Z",
            "data": {
                "places": [
                    {
                        "id": "place_valid_1",
                        "name": "Kyoto Temple",
                        "country": "Japan",
                        "lat": 35.0116,
                        "lon": 135.7681,
                        "precision": "exact",
                        "provenance": "geocoded_result"
                    },
                    {
                        "id": "place_invalid_null_island",
                        "name": "Corrupt Place",
                        "lat": null,
                        "lon": null
                    },
                    {
                        "id": "place_invalid_oob",
                        "name": "Out of Bounds Place",
                        "lat": 95.0,
                        "lon": 190.0
                    },
                    {
                        "id": "place_empty_name",
                        "name": "   ",
                        "lat": 45.0,
                        "lon": 9.0
                    }
                ],
                "discoveries": [
                    {
                        "id": "disc_1",
                        "url": "https://instagram.com/p/123",
                        "caption": "Beautiful Amalfi coast",
                        "collection": "Dream trips",
                        "status": "NEEDS_CONFIRMATION"
                    }
                ]
            }
        }
        """
        
        let result = try LegacyBackupImporter.parseAndImport(
            jsonString: jsonString,
            mode: .merge,
            context: modelContext
        )
        
        // 1 valid place imported, 3 invalid places skipped
        XCTAssertEqual(result.importedPlacesCount, 1)
        XCTAssertEqual(result.skippedPlacesCount, 3)
        XCTAssertEqual(result.importedDiscoveriesCount, 1)
        
        // Check database
        let places = try modelContext.fetch(FetchDescriptor<Place>())
        XCTAssertEqual(places.count, 1)
        XCTAssertEqual(places.first?.name, "Kyoto Temple")
        XCTAssertEqual(places.first?.latitude, 35.0116)
        XCTAssertEqual(places.first?.longitude, 135.7681)
        XCTAssertEqual(places.first?.provenance, .geocodedResult)
    }
    
    func testNativeExportAndReimportRoundtrip() throws {
        let place = Place(
            id: "p_roundtrip",
            name: "Matterhorn",
            country: "Switzerland",
            latitude: 45.9763,
            longitude: 7.6586,
            provenance: .verifiedLink
        )
        let collection = CollectionModel(id: "c_roundtrip", name: "Alps Expedition")
        place.collections = [collection]
        
        let exportedJSON = try NativeBackupService.exportBackup(
            places: [place],
            discoveries: [],
            collections: [collection]
        )
        
        XCTAssertTrue(exportedJSON.contains("waypoints.native.v1"))
        XCTAssertTrue(exportedJSON.contains("Matterhorn"))
        XCTAssertTrue(exportedJSON.contains("45.9763"))
        
        // Reimport in replace mode
        let importResult = try LegacyBackupImporter.parseAndImport(
            jsonString: exportedJSON,
            mode: .replace,
            context: modelContext
        )
        
        XCTAssertEqual(importResult.importedPlacesCount, 1)
        let importedPlaces = try modelContext.fetch(FetchDescriptor<Place>())
        XCTAssertEqual(importedPlaces.count, 1)
        XCTAssertEqual(importedPlaces.first?.name, "Matterhorn")
        XCTAssertEqual(importedPlaces.first?.latitude, 45.9763)
    }
}
