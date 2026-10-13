import SwiftUI
import SwiftData

public struct DuplicateCandidatePair: Identifiable {
    public let id: String
    public let placeA: Place
    public let placeB: Place
    public let distanceMeters: Double
    public let reason: String
}

public struct DuplicateReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [Place]
    
    @State private var dismissedPairIds: Set<String> = []
    @State private var showingMergeSuccessAlert = false
    @State private var mergedPlaceName = ""
    
    public init() {}
    
    private var duplicatePairs: [DuplicateCandidatePair] {
        var pairs: [DuplicateCandidatePair] = []
        let count = places.count
        guard count >= 2 else { return [] }
        
        for i in 0..<(count - 1) {
            for j in (i + 1)..<count {
                let p1 = places[i]
                let p2 = places[j]
                
                let pairId = [p1.id, p2.id].sorted().joined(separator: "_")
                if dismissedPairIds.contains(pairId) { continue }
                
                let distKm = CoordinateMath.haversineDistanceKm(
                    lat1: p1.latitude, lon1: p1.longitude,
                    lat2: p2.latitude, lon2: p2.longitude
                )
                let distMeters = distKm * 1000.0
                
                let n1 = p1.name.lowercased().trimmingCharacters(in: .whitespaces)
                let n2 = p2.name.lowercased().trimmingCharacters(in: .whitespaces)
                let namesMatch = n1 == n2 || n1.contains(n2) || n2.contains(n1)
                
                if distMeters <= 350.0 || (namesMatch && distMeters <= 5000.0) {
                    let reason = distMeters <= 50.0
                        ? "Nearly identical coordinates (\(Int(distMeters))m apart)"
                        : (namesMatch ? "Similar name & located \(String(format: "%.1f km", distKm)) apart" : "Nearby coordinates (\(Int(distMeters))m apart)")
                    
                    pairs.append(DuplicateCandidatePair(
                        id: pairId,
                        placeA: p1,
                        placeB: p2,
                        distanceMeters: distMeters,
                        reason: reason
                    ))
                }
            }
        }
        return pairs
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Review Potential Duplicates")
                            .font(WaypointsTypography.display(20))
                            .foregroundStyle(WaypointsColors.deepForest)
                        
                        Text("Waypoints never silently merges destinations. Compare details side-by-side and decide whether to combine records or keep them separate.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    
                    if duplicatePairs.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(duplicatePairs) { pair in
                                duplicateComparisonCard(pair)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(WaypointsColors.sandLight.ignoresSafeArea())
            .navigationTitle("Duplicate Review")
            .alert("Waypoints Merged", isPresented: $showingMergeSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Successfully merged into '\(mergedPlaceName)'. Source references, notes, and photos were safely consolidated.")
            }
        }
    }
    
    private func duplicateComparisonCard(_ pair: DuplicateCandidatePair) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Match Reason Badge
            HStack {
                Label(pair.reason, systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(WaypointsColors.terracotta)
                Spacer()
            }
            .padding(.bottom, 2)
            
            // Side-by-Side Comparison
            HStack(alignment: .top, spacing: 12) {
                placeMiniCard(place: pair.placeA, label: "Waypoint A")
                placeMiniCard(place: pair.placeB, label: "Waypoint B")
            }
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button {
                    mergePlaces(keep: pair.placeA, discard: pair.placeB, pairId: pair.id)
                } label: {
                    Text("Merge into A")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(WaypointsColors.deepForest)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button {
                    dismissedPairIds.insert(pair.id)
                } label: {
                    Text("Keep Separate")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func placeMiniCard(place: Place, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text(place.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WaypointsColors.deepForest)
                .lineLimit(2)
            
            Text(place.formattedCoordinates)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
            
            if !place.country.isEmpty {
                Text(place.country)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 8) {
                if !place.imageFileNames.isEmpty {
                    Label("\(place.imageFileNames.count)", systemName: "photo")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if !place.sourceReferences.isEmpty {
                    Label("\(place.sourceReferences.count)", systemName: "link")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(WaypointsColors.sandLight.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(WaypointsColors.deepForest.opacity(0.4))
            
            Text("No Duplicates Detected")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text("All of your saved waypoints appear distinct and geographically unique.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private func mergePlaces(keep: Place, discard: Place, pairId: String) {
        // 1. Transfer source references
        for ref in discard.sourceReferences {
            keep.addSourceReference(ref)
        }
        if let discURL = discard.sourceURL, !discURL.isEmpty {
            keep.addSourceReference(SourceReference(url: discURL, platformName: "Merged Source", title: discard.name))
        }
        
        // 2. Transfer image attachments
        for img in discard.imageFileNames {
            keep.addImageFileName(img)
        }
        
        // 3. Consolidate notes
        if !discard.note.isEmpty && !keep.note.contains(discard.note) {
            if keep.note.isEmpty {
                keep.note = discard.note
            } else {
                keep.note += "\n" + discard.note
            }
        }
        
        // 4. Consolidate collections
        for col in discard.collections {
            if !keep.collections.contains(where: { $0.id == col.id }) {
                keep.collections.append(col)
            }
        }
        
        // 5. Delete discarded place safely
        dismissedPairIds.insert(pairId)
        mergedPlaceName = keep.name
        modelContext.delete(discard)
        try? modelContext.save()
        showingMergeSuccessAlert = true
    }
}
