import Foundation

public enum ContentType: Equatable, Sendable {
    case url(URL)
    case coordinates(latitude: Double, longitude: Double)
    case image(Data)
    case text(String)
}

public enum ContentClassifier {
    public static func classify(_ input: String) -> ContentType {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Direct coordinates check (e.g. "34.9671, 135.7727")
        if let coords = CoordinateValidator.parseCoordinate(
            latitudeString: trimmed.components(separatedBy: CharacterSet(charactersIn: ",; ")).first,
            longitudeString: trimmed.components(separatedBy: CharacterSet(charactersIn: ",; ")).last
        ) {
            return .coordinates(latitude: coords.latitude, longitude: coords.longitude)
        }
        
        // 2. URL check
        if (trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")),
           let url = URL(string: trimmed),
           url.host != nil {
            return .url(url)
        }
        
        // 3. Fallback to general text / place name
        return .text(trimmed)
    }
}
