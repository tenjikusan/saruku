import XCTest
@testable import Waypoints

final class IntelligentCategorizerTests: XCTestCase {
    
    func testSuggestCategoryBasedOnKeywords() {
        XCTAssertEqual(
            IntelligentCategorizer.suggestCategory(name: "Fushimi Inari Taisha", note: "Sacred Torii gates", country: "Japan"),
            "Temples & Shrines"
        )
        
        XCTAssertEqual(
            IntelligentCategorizer.suggestCategory(name: "Anse Source d'Argent", note: "Pink granite beach and turquoise water", country: "Seychelles"),
            "Beaches & Coasts"
        )
        
        XCTAssertEqual(
            IntelligentCategorizer.suggestCategory(name: "Matterhorn Summit Trail", note: "Alpine hike through the pass", country: "Switzerland"),
            "Mountains & Hiking"
        )
        
        XCTAssertEqual(
            IntelligentCategorizer.suggestCategory(name: "Osteria Francescana", note: "Michelin 3-star dining and restaurant experience", country: "Italy"),
            "Food & Dining"
        )
        
        XCTAssertEqual(
            IntelligentCategorizer.suggestCategory(name: "Louvre Museum", note: "Historic art exhibition and gallery", country: "France"),
            "Museums & Art"
        )
        
        XCTAssertEqual(
            IntelligentCategorizer.suggestCategory(name: "Neuschwanstein Castle", note: "Bavarian fortress and palace", country: "Germany"),
            "Historic Sites"
        )
        
        XCTAssertEqual(
            IntelligentCategorizer.suggestCategory(name: "Plitvice Lakes National Park", note: "Cascading waterfalls and nature trails", country: "Croatia"),
            "Nature & Parks"
        )
        
        XCTAssertEqual(
            IntelligentCategorizer.suggestCategory(name: "Glacier Point Viewpoint", note: "Spectacular panorama overlooking Yosemite valley", country: "United States"),
            "Scenic Viewpoints"
        )
    }
}
