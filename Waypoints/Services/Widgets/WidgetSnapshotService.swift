import Foundation
import WidgetKit

public struct WidgetDataSnapshot: Codable, Sendable {
    public let savedCount: Int
    public let visitedCount: Int
    public let pendingDiscoveriesCount: Int
    public let recentPlaceName: String?
    public let recentPlaceCountry: String?
    public let favoritePlaceName: String?
    public let favoritePlaceCountry: String?
    public let nextTripName: String?
    public let nextTripDays: Int?
    public let updatedAt: Date
}

/// Creates lightweight, non-blocking shared data snapshots for Home Screen widgets.
public enum WidgetSnapshotService {
    private static let appGroupID = "group.com.waypoints.atlas"
    private static let snapshotFileName = "WidgetSnapshot.json"
    
    public static var snapshotFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(snapshotFileName)
    }
    
    #if !WIDGET_EXTENSION
    public static func updateSnapshot(
        places: [Place],
        discoveries: [Discovery],
        trips: [Trip]
    ) {
        let visited = places.filter { $0.isVisited }.count
        let pending = discoveries.filter { $0.status == .savedAwaiting || $0.status == .needsConfirmation }.count
        let recent = places.sorted { $0.createdAt > $1.createdAt }.first
        let fav = places.filter { $0.isFavorite }.first
        let nextTrip = trips.filter { $0.startDate >= Date() }.sorted { $0.startDate < $1.startDate }.first
        
        let snapshot = WidgetDataSnapshot(
            savedCount: places.count,
            visitedCount: visited,
            pendingDiscoveriesCount: pending,
            recentPlaceName: recent?.name,
            recentPlaceCountry: recent?.country,
            favoritePlaceName: fav?.name,
            favoritePlaceCountry: fav?.country,
            nextTripName: nextTrip?.name,
            nextTripDays: nextTrip?.durationInDays,
            updatedAt: Date()
        )
        
        guard let url = snapshotFileURL,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        
        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }
    #endif
    
    public static func readSnapshot() -> WidgetDataSnapshot? {
        guard let url = snapshotFileURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetDataSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}
