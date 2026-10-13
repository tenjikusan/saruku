import XCTest
@testable import Waypoints

final class AppGroupQueueTests: XCTestCase {
    
    func testSharedItemSerializationRoundtrip() throws {
        let item = SharedItem(
            id: "test_123",
            urlString: "https://maps.apple.com/?ll=45.0,9.0",
            text: "Lake Como notes",
            imageFileName: "photo.jpg",
            timestamp: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        decoder.dateEncodingStrategy = .iso8601
        let decoded = try decoder.decode(SharedItem.self, from: data)
        
        XCTAssertEqual(decoded.id, "test_123")
        XCTAssertEqual(decoded.urlString, "https://maps.apple.com/?ll=45.0,9.0")
        XCTAssertEqual(decoded.text, "Lake Como notes")
        XCTAssertEqual(decoded.imageFileName, "photo.jpg")
        XCTAssertEqual(decoded.url, decoded.urlString)
        XCTAssertEqual(decoded.caption, decoded.text)
    }
    
    func testQueueConfiguration() {
        let queue = AppGroupShareQueue()
        XCTAssertEqual(queue.appGroupID, "group.com.waypoints.atlas")
    }
}
