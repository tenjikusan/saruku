import SwiftUI

public struct SettingsView: View {
    @AppStorage("locationiq_api_key") private var locationIQKey: String = ""
    @AppStorage("offline_geocoding_enabled") private var offlineGeocodingEnabled: Bool = true
    @AppStorage("waypoints_cloudkit_enabled") private var cloudKitEnabled: Bool = false
    
    @State private var showingCacheClearedAlert = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // Section 1: Intelligent Organization & Tools
                Section("Organization & Travel Tools") {
                    NavigationLink {
                        DuplicateReviewView()
                    } label: {
                        Label("Review Duplicate Waypoints", systemName: "arrow.triangle.merge")
                    }
                    
                    NavigationLink {
                        DiscoveryCleanupView()
                    } label: {
                        Label("Cleanup Discovery Inbox", systemName: "sparkles")
                    }
                    
                    NavigationLink {
                        JournalListView()
                    } label: {
                        Label("Travel Journal & Passport", systemName: "book.pages")
                    }
                    
                    NavigationLink {
                        NearbyPlacesView()
                    } label: {
                        Label("Near Me (Saved Destinations)", systemName: "location.circle")
                    }
                }
                
                // Section 2: Geocoding & Intelligence
                Section("Location Intelligence") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Primary Geocoder")
                                .font(.subheadline)
                            Text("Photon / OpenStreetMap (Real Worldwide Search)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                    
                    Toggle(isOn: $offlineGeocodingEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Offline Knowledge Base")
                                .font(.subheadline)
                            Text("Fallback instant lookup for 50+ major destinations without internet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Optional LocationIQ API Key")
                            .font(.subheadline)
                        SecureField("Optional fallback token (pk.xxx)", text: $locationIQKey)
                            .font(.system(size: 14, design: .monospaced))
                            .textFieldStyle(.roundedBorder)
                        Text("Waypoints works completely free without an API key using Photon OSM. Add an optional key only if you need higher query burst limits.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Button {
                        GeocodingEngine.shared.clearCache()
                        showingCacheClearedAlert = true
                    } label: {
                        Text("Clear Geocoding Cache")
                            .font(.subheadline)
                            .foregroundStyle(WaypointsColors.brandPrimary)
                    }
                }
                
                // Section 3: Apple Native Frameworks
                Section("Apple Native Frameworks") {
                    HStack {
                        Label("Apple Vision OCR", systemName: "text.viewfinder")
                        Spacer()
                        Text("On-Device")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Apple NaturalLanguage", systemName: "character.book.closed")
                        Spacer()
                        Text("On-Device")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("App Group Share Queue", systemName: "square.and.arrow.up")
                        Spacer()
                        Text("group.com.waypoints.atlas")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Section 4: iCloud Synchronization
                Section("Cloud Synchronization") {
                    Toggle("iCloud Sync (Preview)", isOn: $cloudKitEnabled)
                    
                    Text(CloudKitSyncService.shared.syncStatus.displayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Section 5: Data & Backup
                Section("Data Management") {
                    NavigationLink {
                        BackupRestoreView()
                    } label: {
                        Label("Backup & Restore Data", systemName: "arrow.triangle.2.circlepath")
                    }
                }
                
                // Section 6: Legal & Attribution
                Section("Open Data & Attribution") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OpenStreetMap Data")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Geocoding results and map coordinates are provided using OpenStreetMap under the Open Database License (ODbL) © OpenStreetMap contributors.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photon by Komoot")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Search autocomplete and geocoding index powered by Photon open-source search engine.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // Section 7: App Info
                Section("About Waypoints") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Native iOS)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("Swift 5.9 • SwiftUI • SwiftData")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Cache Cleared", isPresented: $showingCacheClearedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The in-memory geocoding LRU cache has been reset.")
            }
        }
    }
}
