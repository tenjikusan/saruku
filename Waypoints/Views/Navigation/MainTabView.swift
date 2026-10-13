import SwiftUI
import SwiftData

public struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var discoveries: [Discovery]
    @Query private var places: [Place]
    @Query private var trips: [Trip]
    
    @State private var selectedTab: TabItem = .globe
    @State private var deepLinkedPlaceId: String? = nil
    
    public enum TabItem: Hashable {
        case globe
        case discoveries
        case places
        case collections
        case settings
    }
    
    public init() {}
    
    private var pendingDiscoveriesCount: Int {
        discoveries.filter { $0.status == .savedAwaiting || $0.status == .needsConfirmation }.count
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            GlobeScreenView()
                .tabItem {
                    Label("Globe", systemName: "globe.europe.africa.fill")
                }
                .tag(TabItem.globe)
            
            DiscoveriesListView()
                .tabItem {
                    Label("Discoveries", systemName: "sparkles")
                }
                .badge(pendingDiscoveriesCount > 0 ? pendingDiscoveriesCount : 0)
                .tag(TabItem.discoveries)
            
            PlacesListView()
                .tabItem {
                    Label("Waypoints", systemName: "mappin.and.ellipse")
                }
                .tag(TabItem.places)
            
            CollectionsView()
                .tabItem {
                    Label("Collections", systemName: "folder.fill")
                }
                .tag(TabItem.collections)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemName: "gearshape.fill")
                }
                .tag(TabItem.settings)
        }
        .tint(WaypointsColors.deepForest)
        .onAppear {
            syncWidgetSnapshot()
        }
        .onChange(of: places.count) { _, _ in
            syncWidgetSnapshot()
        }
        .onChange(of: discoveries.count) { _, _ in
            syncWidgetSnapshot()
        }
        .onChange(of: trips.count) { _, _ in
            syncWidgetSnapshot()
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
    }
    
    private func syncWidgetSnapshot() {
        WidgetSnapshotService.updateSnapshot(
            places: places,
            discoveries: discoveries,
            trips: trips
        )
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard let destination = DeepLinkRouter.parse(url: url) else { return }
        
        switch destination {
        case .globe:
            selectedTab = .globe
        case .discoveries, .discovery:
            selectedTab = .discoveries
        case .places, .favorites, .search, .place:
            selectedTab = .places
        case .collections, .trip, .journal:
            selectedTab = .collections
        }
    }
}
