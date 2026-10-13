import SwiftUI
import SwiftData

public struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var discoveries: [Discovery]
    
    @State private var selectedTab: TabItem = .globe
    
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
    }
}
