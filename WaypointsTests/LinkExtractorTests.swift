import XCTest
@testable import Waypoints

final class LinkExtractorTests: XCTestCase {
    
    func testGoogleMapsBang3d4dExtraction() {
        let url = "https://www.google.com/maps/place/Lake+Como/@45.9867,9.2561,12z/data=!3m1!4b1!4m6!3m5!1s0x4784179375e110cb:0x7e2213e4b3e5828f!8m2!3d45.9867492!4d9.2561284!16zL20vMDF3NWYx"
        let result = LinkExtractor.extractCoordinates(from: url)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.precision, "exact")
        XCTAssertEqual(result?.latitude ?? 0, 45.9867492, accuracy: 1e-4)
        XCTAssertEqual(result?.longitude ?? 0, 9.2561284, accuracy: 1e-4)
        XCTAssertEqual(result?.provenance, .verifiedLink)
    }
    
    func testGoogleMapsQueryParamExtraction() {
        let url = "https://maps.google.com/?q=48.8584,2.2945"
        let result = LinkExtractor.extractCoordinates(from: url)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.precision, "exact")
        XCTAssertEqual(result?.latitude ?? 0, 48.8584, accuracy: 1e-4)
        XCTAssertEqual(result?.longitude ?? 0, 2.2945, accuracy: 1e-4)
    }
    
    func testGoogleMapsViewportCenterExtraction() {
        let url = "https://www.google.com/maps/@35.6762,139.6503,14z"
        let result = LinkExtractor.extractCoordinates(from: url)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.precision, "approximate")
        XCTAssertEqual(result?.latitude ?? 0, 35.6762, accuracy: 1e-4)
        XCTAssertEqual(result?.longitude ?? 0, 139.6503, accuracy: 1e-4)
        XCTAssertTrue(result?.requiresConfirmation ?? false)
    }
    
    func testAppleMapsExtraction() {
        let url = "https://maps.apple.com/?ll=37.7749,-122.4194&q=San+Francisco"
        let result = LinkExtractor.extractCoordinates(from: url)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.latitude ?? 0, 37.7749, accuracy: 1e-4)
        XCTAssertEqual(result?.longitude ?? 0, -122.4194, accuracy: 1e-4)
    }
    
    func testOpenStreetMapMarkerExtraction() {
        let url = "https://www.openstreetmap.org/?mlat=51.5074&mlon=-0.1278#map=12/51.5074/-0.1278"
        let result = LinkExtractor.extractCoordinates(from: url)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.latitude ?? 0, 51.5074, accuracy: 1e-4)
        XCTAssertEqual(result?.longitude ?? 0, -0.1278, accuracy: 1e-4)
    }
    
    func testTextCoordinateExtraction() {
        let text = "Coordinates are 45.9867, 9.2561 in northern Italy."
        let result = LinkExtractor.extractCoordinates(fromText: text)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.latitude ?? 0, 45.9867, accuracy: 1e-4)
        XCTAssertEqual(result?.longitude ?? 0, 9.2561, accuracy: 1e-4)
    }
    
    func testPlaceClueExtractionFromHashtag() {
        let caption = "Exploring magical #LakeComo in Italy with @friends #travel"
        let clues = LinkExtractor.extractPlaceNameCandidates(url: "https://instagram.com/p/123", caption: caption)
        
        let foundLakeComo = clues.contains(where: { $0.name.contains("Lake Como") })
        XCTAssertTrue(foundLakeComo, "Should extract 'Lake Como' from camelCase hashtag #LakeComo")
        
        let foundGeneric = clues.contains(where: { $0.name.lowercased() == "travel" })
        XCTAssertFalse(foundGeneric, "Generic travel hashtags must be filtered out")
    }
}
