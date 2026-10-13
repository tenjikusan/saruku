import SwiftUI
import SwiftData

public struct DiscoveryCleanupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Discovery.createdAt, order: .reverse) private var discoveries: [Discovery]
    
    @State private var showingDeleteAllConfirmation = false
    @State private var isRetryingAll = false
    
    public init() {}
    
    private var cleanupCandidates: [Discovery] {
        discoveries.filter { $0.status == .needsInfo || $0.status == .failed || $0.status == .savedAwaiting }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Discovery Inbox Cleanup")
                            .font(WaypointsTypography.display(20))
                            .foregroundStyle(WaypointsColors.deepForest)
                        
                        Text("Review and tidy up discoveries that need additional details, failed lookups, or have been pending for a while.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    if cleanupCandidates.isEmpty {
                        emptyState
                    } else {
                        // Bulk Actions
                        HStack(spacing: 12) {
                            Button {
                                retryAll()
                            } label: {
                                HStack(spacing: 6) {
                                    if isRetryingAll {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Retry All (\(cleanupCandidates.count))")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(WaypointsColors.deepForest)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .disabled(isRetryingAll)
                            
                            Button(role: .destructive) {
                                showingDeleteAllConfirmation = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text("Clear All")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.12))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        
                        // List of items
                        LazyVStack(spacing: 12) {
                            ForEach(cleanupCandidates) { disc in
                                cleanupRow(disc)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(WaypointsColors.sandLight.ignoresSafeArea())
            .navigationTitle("Cleanup Inbox")
            .alert("Clear Unidentified Discoveries", isPresented: $showingDeleteAllConfirmation) {
                Button("Delete All", role: .destructive) {
                    deleteAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \(cleanupCandidates.count) pending or unidentified discoveries?")
            }
        }
    }
    
    private func cleanupRow(_ disc: Discovery) -> some View {
        HStack(spacing: 12) {
            Image(systemName: disc.status.systemIcon)
                .font(.title3)
                .foregroundStyle(Color(hex: disc.status.badgeColorHex))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(disc.caption.isEmpty ? (disc.originalURL.isEmpty ? "Untitled Discovery" : disc.originalURL) : disc.caption)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WaypointsColors.deepForest)
                    .lineLimit(1)
                
                Text(disc.statusMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                modelContext.delete(disc)
                try? modelContext.save()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(WaypointsColors.deepForest.opacity(0.4))
            
            Text("Discovery Inbox is Clean")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text("No failed lookups or old unconfirmed discoveries require attention.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private func retryAll() {
        isRetryingAll = true
        Task {
            for disc in cleanupCandidates {
                _ = await DiscoveryPipeline.shared.identifyLocation(for: disc)
            }
            await MainActor.run {
                try? modelContext.save()
                isRetryingAll = false
            }
        }
    }
    
    private func deleteAll() {
        for disc in cleanupCandidates {
            modelContext.delete(disc)
        }
        try? modelContext.save()
    }
}
