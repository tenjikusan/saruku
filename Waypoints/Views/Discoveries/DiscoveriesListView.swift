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
                                },
                                onDismiss: {
                                    modelContext.delete(disc)
                                    try? modelContext.save()
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
                AddDiscoverySheet { url, caption, collection, imageFileNames in
                    saveNewDiscovery(url: url, caption: caption, collection: collection, imageFileNames: imageFileNames)
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
    
    private func saveNewDiscovery(url: String, caption: String, collection: String, imageFileNames: [String]) {
        let disc = Discovery(
            originalURL: url,
            caption: caption,
            collectionName: collection
        )
        disc.imageFileNames = imageFileNames
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
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Source Type Pill and Status Badge
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: discovery.platformIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.waypointsTerracotta)
                    Text(discovery.platformTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WaypointsColors.deepForest)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#F4EFE6"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Spacer()
                
                StatusBadge(status: discovery.status)
            }
            
            // Quoted Caption Block
            if !discovery.caption.isEmpty {
                Text("\"\(discovery.caption)\"")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(WaypointsColors.deepForest)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#F9F8F5"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            }
            
            // Detected Clues Chips
            if !discovery.candidates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundStyle(WaypointsColors.sunsetAmber)
                        Text("✨ Vision & NL Clues Detected (\(discovery.candidates.count)):")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(discovery.candidates) { cand in
                                HStack(spacing: 4) {
                                    Text("📍")
                                        .font(.system(size: 11))
                                    Text(cand.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(WaypointsColors.deepForest)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: "#F4EFE6"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(WaypointsColors.deepForest.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
            
            // URL Subtitle if available
            if !discovery.originalURL.isEmpty {
                Text(discovery.originalURL)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                if isIdentifying {
                    HStack(spacing: 6) {
                        ProgressView()
                            .tint(WaypointsColors.deepForest)
                        Text("Identifying…")
                            .font(.caption)
                            .foregroundStyle(WaypointsColors.deepForest)
                    }
                    .padding(.vertical, 4)
                } else if discovery.status == .needsConfirmation || !discovery.candidates.isEmpty {
                    Button(action: onReview) {
                        Text(discovery.candidates.count > 1 ? "Confirm & Pin (\(discovery.candidates.count))" : "Confirm & Pin")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(WaypointsColors.deepForest)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                            )
                    }
                } else if discovery.status == .locationConfirmed {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(WaypointsColors.deepForest)
                        Text("Pinned on Globe")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WaypointsColors.deepForest)
                    }
                    .padding(.vertical, 4)
                } else {
                    Button(action: onIdentify) {
                        Text("Find Location ➔")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(WaypointsColors.deepForest)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
