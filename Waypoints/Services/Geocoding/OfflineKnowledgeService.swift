import Foundation

/// Fast, 100% offline geospatial knowledge index.
/// Explicitly marks candidates with .demoData provenance and isDemo = true so they are never confused with live provider results.
public final class OfflineKnowledgeService: GeocodingService, @unchecked Sendable {
    public let name = "Offline Demo Index"
    public let attribution = "Waypoints Offline Demo Index"
    public var isEnabled: Bool = true
    
    public struct OfflineEntry: Sendable {
        public let name: String
        public let country: String
        public let latitude: Double
        public let longitude: Double
        public let precision: String
        public let aliases: [String]
    }
    
    public let database: [OfflineEntry]
    
    public init(customEntries: [OfflineEntry] = []) {
        var base = Self.defaultDatabase
        base.append(contentsOf: customEntries)
        self.database = base
    }
    
    public func searchPlaces(query: String) async throws -> [LocationCandidate] {
        guard isEnabled else { return [] }
        
        let q = clean(query)
        guard q.count >= 2 else { return [] }
        
        var scored: [(score: Int, entry: OfflineEntry)] = []
        
        for item in database {
            let nameClean = clean(item.name)
            let countryClean = clean(item.country)
            let aliasesClean = item.aliases.map { clean($0) }
            
            var score = 0
            if nameClean == q {
                score = 100
            } else if aliasesClean.contains(q) {
                score = 90
            } else if nameClean.contains(q) {
                score = 75
            } else if aliasesClean.contains(where: { $0.contains(q) }) {
                score = 65
            } else if countryClean.contains(q) {
                score = 50
            } else {
                let qWords = q.components(separatedBy: " ").filter { $0.count > 2 }
                let matchedWords = qWords.filter { word in
                    nameClean.contains(word) || countryClean.contains(word) || aliasesClean.contains(where: { a in a.contains(word) })
                }
                if !matchedWords.isEmpty {
                    score = 30 + matchedWords.count * 10
                }
            }
            
            if score > 0 {
                scored.append((score, item))
            }
        }
        
        scored.sort { $0.score > $1.score }
        
        return scored.prefix(5).map { match in
            LocationCandidate(
                name: match.entry.name,
                country: match.entry.country,
                latitude: match.entry.latitude,
                longitude: match.entry.longitude,
                precision: match.entry.precision,
                source: "Offline Demo Index",
                attribution: self.attribution,
                evidence: "Matched \"\(query)\" in offline demo index",
                provenance: .demoData,
                requiresConfirmation: false,
                isDemo: true
            )
        }
    }
    
    private func clean(_ str: String) -> String {
        str.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    public static let defaultDatabase: [OfflineEntry] = [
        // Asia
        OfflineEntry(name: "Fushimi Inari Taisha", country: "Kyoto, Japan", latitude: 34.9671, longitude: 135.7727, precision: "exact", aliases: ["fushimi inari", "torii gates", "kyoto shrine"]),
        OfflineEntry(name: "Kinkaku-ji", country: "Kyoto, Japan", latitude: 35.0394, longitude: 135.7292, precision: "exact", aliases: ["golden pavilion", "kinkakuji"]),
        OfflineEntry(name: "Kyoto", country: "Kansai, Japan", latitude: 35.0116, longitude: 135.7681, precision: "area", aliases: ["kyoto city", "kyoto prefecture"]),
        OfflineEntry(name: "Tokyo Tower", country: "Tokyo, Japan", latitude: 35.6586, longitude: 139.7454, precision: "exact", aliases: ["tokyo tower"]),
        OfflineEntry(name: "Shibuya Crossing", country: "Tokyo, Japan", latitude: 35.6595, longitude: 139.7004, precision: "exact", aliases: ["shibuya", "shibuya scramble"]),
        OfflineEntry(name: "Mount Fuji", country: "Shizuoka / Yamanashi, Japan", latitude: 35.3606, longitude: 138.7274, precision: "exact", aliases: ["fujisan", "fuji mountain"]),
        OfflineEntry(name: "Taj Mahal", country: "Agra, Uttar Pradesh, India", latitude: 27.1751, longitude: 78.0421, precision: "exact", aliases: ["taj mahal agra", "tajmahal"]),
        OfflineEntry(name: "Marina Bay Sands", country: "Singapore", latitude: 1.2834, longitude: 103.8607, precision: "exact", aliases: ["marina bay", "mbs singapore"]),
        OfflineEntry(name: "Nusa Penida", country: "Bali, Indonesia", latitude: -8.7278, longitude: 115.5444, precision: "area", aliases: ["kelingking beach", "nusa penida island"]),
        
        // Europe
        OfflineEntry(name: "Eiffel Tower", country: "Paris, France", latitude: 48.8584, longitude: 2.2945, precision: "exact", aliases: ["eiffel tower", "tour eiffel"]),
        OfflineEntry(name: "Louvre Museum", country: "Paris, France", latitude: 48.8606, longitude: 2.3376, precision: "exact", aliases: ["louvre", "musee du louvre"]),
        OfflineEntry(name: "Colosseum", country: "Rome, Italy", latitude: 41.8902, longitude: 12.4922, precision: "exact", aliases: ["colosseo", "flavian amphitheatre"]),
        OfflineEntry(name: "Lake Como", country: "Lombardy, Italy", latitude: 46.0160, longitude: 9.2572, precision: "area", aliases: ["lake como italy", "bellagio"]),
        OfflineEntry(name: "Dolomites", country: "South Tyrol, Italy", latitude: 46.4983, longitude: 11.3548, precision: "area", aliases: ["dolomiti", "tre cime"]),
        OfflineEntry(name: "Sagrada Familia", country: "Barcelona, Spain", latitude: 41.4036, longitude: 2.1744, precision: "exact", aliases: ["sagrada familia gaudi"]),
        OfflineEntry(name: "Neuschwanstein Castle", country: "Bavaria, Germany", latitude: 47.5576, longitude: 10.7498, precision: "exact", aliases: ["neuschwanstein"]),
        OfflineEntry(name: "Santorini", country: "Cyclades, Greece", latitude: 36.3932, longitude: 25.4615, precision: "area", aliases: ["oia", "thira"]),
        OfflineEntry(name: "Big Ben", country: "London, United Kingdom", latitude: 51.5007, longitude: -0.1246, precision: "exact", aliases: ["elizabeth tower"]),
        
        // Americas
        OfflineEntry(name: "Statue of Liberty", country: "New York, USA", latitude: 40.6892, longitude: -74.0445, precision: "exact", aliases: ["statue of liberty", "lady liberty"]),
        OfflineEntry(name: "Central Park", country: "New York, USA", latitude: 40.7851, longitude: -73.9683, precision: "exact", aliases: ["central park nyc"]),
        OfflineEntry(name: "Golden Gate Bridge", country: "San Francisco, California, USA", latitude: 37.8199, longitude: -122.4783, precision: "exact", aliases: ["golden gate"]),
        OfflineEntry(name: "Grand Canyon", country: "Arizona, USA", latitude: 36.1069, longitude: -112.1129, precision: "area", aliases: ["grand canyon national park"]),
        OfflineEntry(name: "Yosemite Valley", country: "California, USA", latitude: 37.7456, longitude: -119.5936, precision: "area", aliases: ["yosemite", "half dome"]),
        OfflineEntry(name: "Banff National Park", country: "Alberta, Canada", latitude: 51.4968, longitude: -115.9281, precision: "area", aliases: ["banff", "lake louise"]),
        OfflineEntry(name: "Machu Picchu", country: "Cusco Region, Peru", latitude: -13.1631, longitude: -72.5450, precision: "exact", aliases: ["machu picchu", "inca citadel"]),
        OfflineEntry(name: "Christ the Redeemer", country: "Rio de Janeiro, Brazil", latitude: -22.9519, longitude: -43.2105, precision: "exact", aliases: ["corcovado rio"]),
        OfflineEntry(name: "Chichen Itza", country: "Yucatan, Mexico", latitude: 20.6843, longitude: -88.5678, precision: "exact", aliases: ["el castillo yucatan"]),
        
        // Africa & Oceania
        OfflineEntry(name: "Pyramids of Giza", country: "Giza, Egypt", latitude: 29.9792, longitude: 31.1342, precision: "exact", aliases: ["great pyramid of giza"]),
        OfflineEntry(name: "Table Mountain", country: "Cape Town, South Africa", latitude: -33.9628, longitude: 18.4098, precision: "exact", aliases: ["table mountain cape town"]),
        OfflineEntry(name: "Sydney Opera House", country: "Sydney, Australia", latitude: -33.8568, longitude: 151.2153, precision: "exact", aliases: ["bennelong point"]),
        OfflineEntry(name: "Milford Sound", country: "South Island, New Zealand", latitude: -44.6414, longitude: 167.8974, precision: "exact", aliases: ["fiordland"])
    ]
}
