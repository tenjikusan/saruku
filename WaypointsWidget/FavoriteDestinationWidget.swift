import WidgetKit
import SwiftUI

public struct FavoriteDestinationWidgetView: View {
    let entry: SharedSnapshotEntry
    
    public init(entry: SharedSnapshotEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color.yellow)
                Text("Favorite Place")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            
            Spacer()
            
            if let fav = entry.snapshot?.favoritePlaceName, !fav.isEmpty {
                Text(fav)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                if let country = entry.snapshot?.favoritePlaceCountry, !country.isEmpty {
                    Text(country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No favorite pinned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Tap the star icon on any place")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Text("\(entry.snapshot?.visitedCount ?? 0) visited")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "globe.europe.africa.fill")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.14, green: 0.29, blue: 0.23))
            }
        }
        .padding()
        .containerBackground(Color(red: 0.98, green: 0.97, blue: 0.95), for: .widget)
        .widgetURL(URL(string: "waypoints://favorites"))
    }
}

public struct FavoriteDestinationWidget: Widget {
    public let kind: String = "WaypointsFavoriteDestinationWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentlySavedProvider()) { entry in
            FavoriteDestinationWidgetView(entry: entry)
        }
        .configurationDisplayName("Favorite Destination")
        .description("Quickly open your starred favorite destination on the 3D globe.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
