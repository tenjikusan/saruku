import SwiftUI
import SwiftData

public struct VisitedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Place> { $0.isVisited }, sort: \Place.updatedAt, order: .reverse)
    private var visitedPlaces: [Place]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Travel Stats Header
                statsHeader
                
                if visitedPlaces.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 48))
                            .foregroundStyle(WaypointsColors.deepForest.opacity(0.3))
                        Text("No Visited Waypoints")
                            .font(WaypointsTypography.title(18))
                            .foregroundStyle(WaypointsColors.deepForest)
                        Text("Mark places you have traveled to as visited to build your personal travel passport.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(visitedPlaces) { place in
                            NavigationLink {
                                PlaceDetailView(place: place)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(WaypointsColors.deepForest)
                                        .font(.system(size: 18))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(place.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(WaypointsColors.deepForest)
                                        if !place.country.isEmpty {
                                            Text(place.country)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(place.formattedCoordinates)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    place.isVisited = false
                                    place.updatedAt = Date()
                                    try? modelContext.save()
                                } label: {
                                    Label("Mark Unvisited", systemName: "circle")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(WaypointsColors.sandLight)
            .navigationTitle("Visited Passport")
        }
    }
    
    private var statsHeader: some View {
        HStack(spacing: 24) {
            statItem(count: visitedPlaces.count, label: "Places Visited", icon: "mappin.circle.fill")
            
            let uniqueCountries = Set(visitedPlaces.map { $0.country.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }).count
            statItem(count: uniqueCountries, label: "Countries / Regions", icon: "globe.europe.africa.fill")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func statItem(count: Int, label: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(WaypointsColors.deepForest)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(WaypointsTypography.display(20))
                    .foregroundStyle(WaypointsColors.deepForest)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
