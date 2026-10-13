import SwiftUI
import SwiftData
import CoreLocation

public struct NearbyPlacesView: View {
    @Environment(\.openURL) private var openURL
    @Query private var places: [Place]
    
    @State private var locationManager = LocationManager.shared
    @State private var selectedRadiusKm: Double = 50.0
    
    let radiusOptions: [Double] = [10.0, 25.0, 50.0, 100.0, 250.0]
    
    public init() {}
    
    private var nearbyPlacesWithDistance: [(place: Place, distanceKm: Double)] {
        guard let userCoord = locationManager.currentCoordinate else { return [] }
        
        var list: [(Place, Double)] = []
        for p in places {
            let dist = CoordinateMath.haversineDistanceKm(
                lat1: userCoord.latitude, lon1: userCoord.longitude,
                lat2: p.latitude, lon2: p.longitude
            )
            if dist <= selectedRadiusKm {
                list.append((p, dist))
            }
        }
        return list.sorted { $0.1 < $1.1 }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Radius Picker Bar
                radiusSelectorBar
                
                // Content
                if locationManager.currentCoordinate == nil {
                    locationRequestPrompt
                } else if nearbyPlacesWithDistance.isEmpty {
                    noNearbyPlacesView
                } else {
                    List {
                        ForEach(nearbyPlacesWithDistance, id: \.place.id) { item in
                            NavigationLink {
                                PlaceDetailView(place: item.place)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.place.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(WaypointsColors.deepForest)
                                        
                                        if !item.place.country.isEmpty {
                                            Text(item.place.country)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(String(format: "%.1f km", item.distanceKm))
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(WaypointsColors.deepForest)
                                        
                                        Button {
                                            openDirections(to: item.place)
                                        } label: {
                                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(WaypointsColors.terracotta)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(WaypointsColors.sandLight)
            .navigationTitle("Near Me")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        locationManager.requestCurrentLocation()
                    } label: {
                        Image(systemName: "location.circle")
                            .foregroundStyle(WaypointsColors.deepForest)
                    }
                }
            }
            .onAppear {
                if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    locationManager.requestCurrentLocation()
                }
            }
        }
    }
    
    private var radiusSelectorBar: some View {
        HStack {
            Text("Radius:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Picker("Radius", selection: $selectedRadiusKm) {
                ForEach(radiusOptions, id: \.self) { r in
                    Text("\(Int(r)) km").tag(r)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
    }
    
    private var locationRequestPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "location.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(WaypointsColors.deepForest.opacity(0.3))
            
            Text("Find Nearby Saved Places")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text("Enable one-time location access to view saved destinations near your current physical position.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                locationManager.requestCurrentLocation()
            } label: {
                Label("Enable Location Access", systemName: "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(WaypointsColors.deepForest)
                    .clipShape(Capsule())
            }
            
            if let err = locationManager.locationError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }
    
    private var noNearbyPlacesView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 48))
                .foregroundStyle(WaypointsColors.deepForest.opacity(0.3))
            
            Text("No Waypoints Within \(Int(selectedRadiusKm)) km")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text("Try expanding the search radius above to include destinations further away.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    private func openDirections(to place: Place) {
        if let url = URL(string: "http://maps.apple.com/?daddr=\(place.latitude),\(place.longitude)&dirflg=d") {
            openURL(url)
        }
    }
}
