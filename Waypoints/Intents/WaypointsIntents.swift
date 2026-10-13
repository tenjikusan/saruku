import Foundation
import AppIntents

public struct OpenGlobeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Waypoints Globe"
    public static var description = IntentDescription("Launches Waypoints directly into the interactive 3D Earth Globe.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

public struct OpenFavoritesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Favorite Places"
    public static var description = IntentDescription("Opens your saved favorite destinations in Waypoints.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

public struct OpenTripIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Upcoming Trip"
    public static var description = IntentDescription("Opens your planned trips and itineraries in Waypoints.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

public struct SearchPlacesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Search Saved Places"
    public static var description = IntentDescription("Opens unified search to find saved places or explore the world.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

public struct AddDiscoveryIntent: AppIntent {
    public static var title: LocalizedStringResource = "Add a Discovery Link"
    public static var description = IntentDescription("Quickly saves a travel URL or location note to Waypoints.")
    public static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Content URL or Text")
    public var content: String
    
    public init() {}
    
    public init(content: String) {
        self.content = content
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let item = SharedItem(
            urlString: content.hasPrefix("http") ? content : nil,
            text: content.hasPrefix("http") ? nil : content
        )
        AppGroupShareQueue.shared.enqueue(item)
        return .result(dialog: "Saved to Waypoints discovery inbox.")
    }
}

public struct WaypointsShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenGlobeIntent(),
            phrases: [
                "Open my \(.applicationName) globe",
                "Show \(.applicationName) 3D Earth"
            ],
            shortTitle: "Open Globe",
            systemImageName: "globe.europe.africa.fill"
        )
        AppShortcut(
            intent: OpenFavoritesIntent(),
            phrases: [
                "Open my \(.applicationName) favorites",
                "Show favorite \(.applicationName)"
            ],
            shortTitle: "Open Favorites",
            systemImageName: "star.fill"
        )
        AppShortcut(
            intent: OpenTripIntent(),
            phrases: [
                "Open my \(.applicationName) trips",
                "Show next trip in \(.applicationName)"
            ],
            shortTitle: "Open Trips",
            systemImageName: "airplane"
        )
        AppShortcut(
            intent: SearchPlacesIntent(),
            phrases: [
                "Search in \(.applicationName)",
                "Find places in \(.applicationName)"
            ],
            shortTitle: "Search Places",
            systemImageName: "magnifyingglass"
        )
    }
}
