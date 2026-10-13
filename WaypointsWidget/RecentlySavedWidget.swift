import WidgetKit
import SwiftUI

public struct SharedSnapshotEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetDataSnapshot?
    
    public init(date: Date, snapshot: WidgetDataSnapshot?) {
        self.date = date
        self.snapshot = snapshot
    }
}

public struct RecentlySavedProvider: TimelineProvider {
    public init() {}
    
    public func placeholder(in context: Context) -> SharedSnapshotEntry {
        SharedSnapshotEntry(
            date: Date(),
            snapshot: WidgetDataSnapshot(
                savedCount: 12,
                visitedCount: 5,
                pendingDiscoveriesCount: 2,
                recentPlaceName: "Lake Como",
                recentPlaceCountry: "Italy",
                favoritePlaceName: "Kyoto",
                favoritePlaceCountry: "Japan",
                nextTripName: "Alpine Summer",
                nextTripDays: 7,
                updatedAt: Date()
            )
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (SharedSnapshotEntry) -> Void) {
        let snapshot = WidgetSnapshotService.readSnapshot()
        completion(SharedSnapshotEntry(date: Date(), snapshot: snapshot))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<SharedSnapshotEntry>) -> Void) {
        let snapshot = WidgetSnapshotService.readSnapshot()
        let entry = SharedSnapshotEntry(date: Date(), snapshot: snapshot)
        // Refresh every 30 minutes or when app notifies
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct RecentlySavedWidgetView: View {
    let entry: SharedSnapshotEntry
    
    public init(entry: SharedSnapshotEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(red: 0.85, green: 0.45, blue: 0.28))
                Text("Recently Saved")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            
            Spacer()
            
            if let name = entry.snapshot?.recentPlaceName, !name.isEmpty {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                if let country = entry.snapshot?.recentPlaceCountry, !country.isEmpty {
                    Text(country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No saved places yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Discover & save destinations")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Text("\(entry.snapshot?.savedCount ?? 0) saved")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.14, green: 0.29, blue: 0.23))
            }
        }
        .padding()
        .containerBackground(Color(red: 0.98, green: 0.97, blue: 0.95), for: .widget)
        .widgetURL(URL(string: "waypoints://places"))
    }
}

public struct RecentlySavedWidget: Widget {
    public let kind: String = "WaypointsRecentlySavedWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentlySavedProvider()) { entry in
            RecentlySavedWidgetView(entry: entry)
        }
        .configurationDisplayName("Recently Saved")
        .description("Quick glance at the last destination you saved to Waypoints.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
