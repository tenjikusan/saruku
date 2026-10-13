import Foundation

public enum DeepLinkDestination: Equatable, Sendable {
    case place(id: String)
    case discovery(id: String)
    case trip(id: String)
    case globe
    case favorites
    case places
    case collections
    case search
    case journal
    case discoveries
}

public enum DeepLinkRouter {
    public static func parse(url: URL) -> DeepLinkDestination? {
        guard url.scheme?.lowercased() == "waypoints" else { return nil }
        
        let host = url.host?.lowercased() ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch host {
        case "globe":
            return .globe
        case "favorites":
            return .favorites
        case "places":
            return .places
        case "collections":
            return .collections
        case "search":
            return .search
        case "journal":
            return .journal
        case "discoveries":
            return .discoveries
        case "place":
            if let id = pathComponents.first, !id.isEmpty {
                return .place(id: id)
            }
            return .places
        case "discovery":
            if let id = pathComponents.first, !id.isEmpty {
                return .discovery(id: id)
            }
            return .discoveries
        case "trip":
            if let id = pathComponents.first, !id.isEmpty {
                return .trip(id: id)
            }
            return .collections
        default:
            break
        }
        
        return nil
    }
}
