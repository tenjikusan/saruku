import SwiftUI
import SwiftData

public struct DiscoveriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    
    @Query(sort: \Discovery.createdAt, order: .reverse)
    private var discoveries: [Discovery]
    
    @State private var selectedStatusFilter: DiscoveryStatus? = nil
    @State private var activeDiscoveryForReview: Discovery? = nil
    @State private var isShowingAddSheet: Bool = false
    @State private var isIdentifyingId: String? = nil
    
    public var onPlaceConfirmed: ((Place) -> Void)? = nil
    public var onPickOnGlobeRequested: (() -> Void)? = nil
    
    public init(
        onPlaceConfirmed: ((Place) -> Void)? = nil,
        onPickOnGlobeRequested: (() -> Void)? = nil
    ) {
        self.onPlaceConfirmed = onPlaceConfirmed
        self.onPickOnGlobeRequested = onPickOnGlobeRequested
    }
    
    private var filteredDiscoveries: [Discovery] {
        if let selectedStatusFilter {
            return discoveries.filter { $0.status == selectedStatusFilter }
        }
        return discoveries
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "All (\(discoveries.count))", isSelected: selectedStatusFilter == nil) {
                            selectedStatusFilter = nil
                        }
                        
                        ForEach([DiscoveryStatus.needsConfirmation, .needsInfo, .locationConfirmed, .savedAwaiting], id: \.self) { st in
                            let count = discoveries.filter { $0.status == st }.count
                            if count > 0 {
                                filterChip(title: "\(st.displayLabel) (\(count))", isSelected: selectedStatusFilter == st) {
                                    selectedStatusFilter = st
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                // Content List or Empty State
                if filteredDiscoveries.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredDiscoveries) { disc in
                            DiscoveryRowView(
                                discovery: disc,
                                isIdentifying: isIdentifyingId == disc.id,
                                onReview: {
                                    activeDiscoveryForReview = disc
                                },
                                onIdentify: {
                                    runIdentification(for: disc)
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteDiscoveries)
                    }
                    .listStyle(.plain)
                }
            }
            .background(WaypointsTheme.background(for: scheme).ignoresSafeArea())
            .navigationTitle("Discoveries Inbox")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Paste")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color.waypointsGreen)
                    }
                }
            }
            .sheet(item: $activeDiscoveryForReview) { disc in
                LocationConfirmationSheet(
                    discovery: disc,
                    onConfirm: { place in
                        modelContext.insert(place)
                        try? modelContext.save()
                        onPlaceConfirmed?(place)
                    },
                    onPickOnGlobeTapped: {
                        onPickOnGlobeRequested?()
                    }
                )
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddDiscoverySheet { url, caption, collection, imageData in
                    saveNewDiscovery(url: url, caption: caption, collection: collection, imageData: imageData)
                }
            }
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(WaypointsTypography.eyebrow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.waypointsGreen : WaypointsTheme.surface(for: scheme))
                .foregroundColor(isSelected ? .white : WaypointsTheme.textPrimary(for: scheme))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.clear : WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.waypointsSage.opacity(0.6))
            
            Text("Your Discovery Inbox is Empty")
                .font(WaypointsTypography.headline)
                .foregroundColor(WaypointsTheme.textPrimary(for: scheme))
            
            Text("Paste travel links from Instagram, blogs, or YouTube, or pick a screenshot to find locations.")
                .font(WaypointsTypography.body)
                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                isShowingAddSheet = true
            } label: {
                Text("＋ Save New Discovery")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.waypointsGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    private func saveNewDiscovery(url: String, caption: String, collection: String, imageData: Data?) {
        let disc = Discovery(
            originalURL: url,
            caption: caption,
            collectionName: collection
        )
        modelContext.insert(disc)
        try? modelContext.save()
        
        runIdentification(for: disc)
    }
    
    private func runIdentification(for disc: Discovery) {
        isIdentifyingId = disc.id
        Task {
            _ = await DiscoveryPipeline.shared.identifyLocation(for: disc)
            await MainActor.run {
                isIdentifyingId = nil
                try? modelContext.save()
                if disc.status == .needsConfirmation {
                    activeDiscoveryForReview = disc
                }
            }
        }
    }
    
    private func deleteDiscoveries(at offsets: IndexSet) {
        for index in offsets {
            let disc = filteredDiscoveries[index]
            modelContext.delete(disc)
        }
        try? modelContext.save()
    }
}

// MARK: - Row View

private struct DiscoveryRowView: View {
    let discovery: Discovery
    let isIdentifying: Bool
    let onReview: () -> Void
    let onIdentify: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    StatusBadge(status: discovery.status)
                    Spacer()
                    Text(discovery.collectionName)
                        .font(WaypointsTypography.eyebrow)
                        .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                }
                
                if !discovery.caption.isEmpty {
                    Text(discovery.caption)
                        .font(WaypointsTypography.subheadline)
                        .foregroundColor(WaypointsTheme.textPrimary(for: scheme))
                        .lineLimit(2)
                }
                
                if !discovery.originalURL.isEmpty {
                    Text(discovery.originalURL)
                        .font(WaypointsTypography.caption)
                        .foregroundColor(Color.waypointsSage)
                        .lineLimit(1)
                }
                
                Text(discovery.statusMessage)
                    .font(WaypointsTypography.caption)
                    .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                    .lineLimit(2)
                
                HStack {
                    Spacer()
                    if isIdentifying {
                        HStack(spacing: 6) {
                            ProgressView()
                                .tint(Color.waypointsGreen)
                            Text("Identifying…")
                                .font(WaypointsTypography.caption)
                                .foregroundColor(Color.waypointsGreen)
                        }
                    } else if discovery.status == .needsConfirmation || discovery.status == .needsInfo {
                        Button {
                            onReview()
                        } label: {
                            Text(discovery.status == .needsConfirmation ? "Review Location 📍" : "Add Location Details")
                                .font(WaypointsTypography.eyebrow)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.waypointsGreen)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else if discovery.status == .savedAwaiting || discovery.status == .failed {
                        Button {
                            onIdentify()
                        } label: {
                            Text("Find Location ➔")
                                .font(WaypointsTypography.eyebrow)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.waypointsSage.opacity(0.2))
                                .foregroundColor(Color.waypointsGreen)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}
