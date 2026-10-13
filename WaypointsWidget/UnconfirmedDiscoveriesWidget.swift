import WidgetKit
import SwiftUI

public struct UnconfirmedDiscoveriesWidgetView: View {
    let entry: SharedSnapshotEntry
    
    public init(entry: SharedSnapshotEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(red: 0.85, green: 0.45, blue: 0.28))
                Text("Discoveries")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            
            Spacer()
            
            let count = entry.snapshot?.pendingDiscoveriesCount ?? 0
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.85, green: 0.45, blue: 0.28))
                
                Text(count == 1 ? "Pending discovery to confirm" : "Pending discoveries to confirm")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text("All Clear")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Share screenshots or URLs from Instagram, TikTok & Safari")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack {
                Text("Open Inbox")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "tray.full.fill")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.14, green: 0.29, blue: 0.23))
            }
        }
        .padding()
        .containerBackground(Color(red: 0.98, green: 0.97, blue: 0.95), for: .widget)
        .widgetURL(URL(string: "waypoints://discoveries"))
    }
}

public struct UnconfirmedDiscoveriesWidget: Widget {
    public let kind: String = "WaypointsUnconfirmedDiscoveriesWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentlySavedProvider()) { entry in
            UnconfirmedDiscoveriesWidgetView(entry: entry)
        }
        .configurationDisplayName("Pending Discoveries")
        .description("Track discoveries captured from social media waiting for your review.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
