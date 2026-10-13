import WidgetKit
import SwiftUI

public struct UpcomingTripWidgetView: View {
    let entry: SharedSnapshotEntry
    
    public init(entry: SharedSnapshotEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "airplane.departure")
                    .foregroundColor(Color(red: 0.14, green: 0.29, blue: 0.23))
                Text("Upcoming Trip")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            
            Spacer()
            
            if let trip = entry.snapshot?.nextTripName, !trip.isEmpty {
                Text(trip)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                if let days = entry.snapshot?.nextTripDays {
                    Text("\(days) days duration")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.85, green: 0.45, blue: 0.28))
                        .fontWeight(.semibold)
                }
            } else {
                Text("No upcoming trips")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Plan an itinerary in Trips")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Text("View Itinerary")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.14, green: 0.29, blue: 0.23))
            }
        }
        .padding()
        .containerBackground(Color(red: 0.98, green: 0.97, blue: 0.95), for: .widget)
        .widgetURL(URL(string: "waypoints://collections"))
    }
}

public struct UpcomingTripWidget: Widget {
    public let kind: String = "WaypointsUpcomingTripWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentlySavedProvider()) { entry in
            UpcomingTripWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Trip")
        .description("Countdown and itinerary details for your next planned journey.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
