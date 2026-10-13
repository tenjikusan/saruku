import SwiftUI
import SwiftData

public struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Place> { $0.isFavorite }, sort: \Place.updatedAt, order: .reverse)
    private var favoritePlaces: [Place]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Group {
                if favoritePlaces.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star")
                            .font(.system(size: 48))
                            .foregroundStyle(WaypointsColors.sunsetAmber.opacity(0.4))
                        Text("No Favorite Waypoints")
                            .font(WaypointsTypography.title(18))
                            .foregroundStyle(WaypointsColors.deepForest)
                        Text("Star your most treasured places to access them quickly here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(favoritePlaces) { place in
                            NavigationLink {
                                PlaceDetailView(place: place)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(WaypointsColors.sunsetAmber)
                                        .font(.system(size: 16))
                                    
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
                                    place.isFavorite = false
                                    place.updatedAt = Date()
                                    try? modelContext.save()
                                } label: {
                                    Label("Remove", systemName: "star.slash")
                                }
                                .tint(WaypointsColors.sunsetAmber)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Favorites")
        }
    }
}
