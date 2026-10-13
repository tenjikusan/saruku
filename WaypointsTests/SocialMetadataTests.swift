import XCTest
@testable import Waypoints

final class SocialMetadataTests: XCTestCase {
    
    func testIdentifyPlatform() {
        let service = SocialMetadataService()
        
        XCTAssertEqual(service.identifyPlatform(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"), "YouTube")
        XCTAssertEqual(service.identifyPlatform(from: "https://youtu.be/dQw4w9WgXcQ"), "YouTube")
        XCTAssertEqual(service.identifyPlatform(from: "https://www.instagram.com/p/Cxyz123"), "Instagram")
        XCTAssertEqual(service.identifyPlatform(from: "https://x.com/travel/status/123"), "X (Twitter)")
        XCTAssertEqual(service.identifyPlatform(from: "https://twitter.com/travel/status/123"), "X (Twitter)")
        XCTAssertEqual(service.identifyPlatform(from: "https://www.tiktok.com/@traveler/video/123"), "TikTok")
        XCTAssertEqual(service.identifyPlatform(from: "https://www.pinterest.com/pin/123"), "Pinterest")
        XCTAssertEqual(service.identifyPlatform(from: "https://en.wikipedia.org/wiki/Kyoto"), "Wikipedia")
    }
    
    func testInvalidURLHandling() async {
        let service = SocialMetadataService()
        let result = await service.fetchMetadata(for: "not a valid url")
        
        XCTAssertFalse(result.isAccessible)
        XCTAssertNotNil(result.notice)
    }
    
    func testLoginWallNoticeForInstagram() async {
        let service = SocialMetadataService()
        let result = await service.fetchMetadata(for: "https://www.instagram.com/p/Cxyz123/")
        
        // Either gets OpenGraph or gives the proper login-wall notice
        if !result.isAccessible {
            XCTAssertNotNil(result.notice)
            XCTAssertTrue(result.notice?.contains("login wall") ?? false || result.notice?.contains("Instagram") ?? false)
        }
    }
}
