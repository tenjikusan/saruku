import SwiftUI
import SwiftData

@main
public struct WaypointsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    let container: ModelContainer
    
    public init() {
        do {
            let schema = Schema([
                Place.self,
                Discovery.self,
                CollectionModel.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
    
    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
                .onAppear {
                    bootstrapDefaultCollectionsIfNeeded()
                    ingestPendingSharedItems()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        ingestPendingSharedItems()
                    }
                }
        }
    }
    
    @MainActor
    private func bootstrapDefaultCollectionsIfNeeded() {
        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<CollectionModel>()
        if let existing = try? context.fetch(fetchDescriptor), existing.isEmpty {
            let defaults = [
                CollectionModel(name: "Dream trips", systemIcon: "airplane", colorHex: "#244B3B"),
                CollectionModel(name: "Hidden gems", systemIcon: "sparkles", colorHex: "#B27C61"),
                CollectionModel(name: "Food & cafes", systemIcon: "cup.and.saucer.fill", colorHex: "#D97447"),
                CollectionModel(name: "Scenic viewpoints", systemIcon: "mountain.2.fill", colorHex: "#5B8E7D")
            ]
            for col in defaults {
                context.insert(col)
            }
            try? context.save()
        }
    }
    
    @MainActor
    private func ingestPendingSharedItems() {
        let items = AppGroupShareQueue.shared.drain()
        guard !items.isEmpty else { return }
        
        let context = container.mainContext
        for item in items {
            let discovery = Discovery(
                originalURL: item.url ?? "",
                caption: item.caption ?? "",
                collectionName: "Dream trips",
                status: .savedAwaiting,
                statusMessage: "Shared from iOS Share Extension"
            )
            
            // Auto-trigger discovery pipeline in background
            Task { @MainActor in
                await DiscoveryPipeline.shared.processDiscovery(discovery: discovery, context: context)
            }
            
            context.insert(discovery)
        }
        
        try? context.save()
    }
}
