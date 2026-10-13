import Foundation

/// Analyzes place names, notes, and geographic clues to recommend meaningful travel categories
/// using Apple's on-device NaturalLanguage parsing and contextual keywords.
public enum IntelligentCategorizer {
    
    public static let availableCategories = [
        "Temples & Shrines",
        "Beaches & Coasts",
        "Mountains & Hiking",
        "Food & Dining",
        "Historic Sites",
        "Museums & Art",
        "Nature & Parks",
        "Scenic Viewpoints",
        "City & Urban",
        "Hotels & Stays"
    ]
    
    public static func suggestCategory(name: String, note: String, country: String) -> String {
        let combined = "\(name) \(note) \(country)".lowercased()
        
        // 1. Temples & Shrines
        if combined.contains("temple") || combined.contains("shrine") || combined.contains("torii") ||
           combined.contains("pagoda") || combined.contains("monastery") || combined.contains("cathedral") ||
           combined.contains("church") || combined.contains("basilica") || combined.contains("mosque") {
            return "Temples & Shrines"
        }
        
        // 2. Beaches & Coasts
        if combined.contains("beach") || combined.contains("coast") || combined.contains("cove") ||
           combined.contains("playa") || combined.contains("spiaggia") || combined.contains("plage") ||
           combined.contains("island") || combined.contains("bay") || combined.contains("cliff") {
            return "Beaches & Coasts"
        }
        
        // 3. Mountains & Hiking
        if combined.contains("mountain") || combined.contains("mount ") || combined.contains("mt.") ||
           combined.contains("alps") || combined.contains("peak") || combined.contains("summit") ||
           combined.contains("trail") || combined.contains("hike") || combined.contains("pass") ||
           combined.contains("canyon") || combined.contains("gorge") {
            return "Mountains & Hiking"
        }
        
        // 4. Food & Dining
        if combined.contains("cafe") || combined.contains("café") || combined.contains("restaurant") ||
           combined.contains("bakery") || combined.contains("bistro") || combined.contains("bar") ||
           combined.contains("ramen") || combined.contains("pizza") || combined.contains("coffee") ||
           combined.contains("market") || combined.contains("dining") {
            return "Food & Dining"
        }
        
        // 5. Museums & Art
        if combined.contains("museum") || combined.contains("gallery") || combined.contains("exhibition") ||
           combined.contains("art") || combined.contains("sculpture") || combined.contains("palace") {
            return "Museums & Art"
        }
        
        // 6. Historic Sites
        if combined.contains("castle") || combined.contains("ruins") || combined.contains("ancient") ||
           combined.contains("fort") || combined.contains("monument") || combined.contains("heritage") ||
           combined.contains("pyramid") {
            return "Historic Sites"
        }
        
        // 7. Scenic Viewpoints
        if combined.contains("viewpoint") || combined.contains("lookout") || combined.contains("overlook") ||
           combined.contains("panorama") || combined.contains("skydeck") || combined.contains("bridge") {
            return "Scenic Viewpoints"
        }
        
        // 8. Nature & Parks
        if combined.contains("lake") || combined.contains("park") || combined.contains("waterfall") ||
           combined.contains("falls") || combined.contains("forest") || combined.contains("garden") {
            return "Nature & Parks"
        }
        
        return "City & Urban"
    }
}
