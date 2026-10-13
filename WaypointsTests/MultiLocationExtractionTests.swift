import XCTest
@testable import Waypoints

final class MultiLocationExtractionTests: XCTestCase {
    
    func testExtractMultipleLocationsFromColonSeparatedSentence() {
        let sentence = "10 beautiful places to visit in Japan: Kyoto, Nara, Osaka, Hakone, and Mount Fuji."
        let clues = NaturalLanguageService.shared.extractListCandidateNames(from: sentence)
        
        let names = clues.map { $0.name.lowercased() }
        XCTAssertTrue(names.contains(where: { $0.contains("kyoto") }), "Should extract Kyoto")
        XCTAssertTrue(names.contains(where: { $0.contains("nara") }), "Should extract Nara")
        XCTAssertTrue(names.contains(where: { $0.contains("osaka") }), "Should extract Osaka")
        XCTAssertTrue(names.contains(where: { $0.contains("hakone") }), "Should extract Hakone")
        XCTAssertTrue(names.contains(where: { $0.contains("mount fuji") }), "Should extract Mount Fuji")
    }
    
    func testExtractMultipleLocationsFromBulletPoints() {
        let text = """
        My dream Italy itinerary:
        - Lake Como
        - Amalfi Coast
        - Dolomites
        """
        let clues = NaturalLanguageService.shared.extractListCandidateNames(from: text)
        let names = clues.map { $0.name.lowercased() }
        
        XCTAssertTrue(names.contains(where: { $0.contains("lake como") }))
        XCTAssertTrue(names.contains(where: { $0.contains("amalfi coast") }))
        XCTAssertTrue(names.contains(where: { $0.contains("dolomites") }))
    }
    
    func testExtractMultipleLocationsFromNumberedList() {
        let text = """
        1. Shibuya Crossing
        2. Fushimi Inari
        3. Arashiyama Bamboo Grove
        """
        let clues = NaturalLanguageService.shared.extractListCandidateNames(from: text)
        let names = clues.map { $0.name.lowercased() }
        
        XCTAssertTrue(names.contains(where: { $0.contains("shibuya crossing") }))
        XCTAssertTrue(names.contains(where: { $0.contains("fushimi inari") }))
        XCTAssertTrue(names.contains(where: { $0.contains("arashiyama") }))
    }
}
