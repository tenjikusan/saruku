import SwiftUI
import SwiftData

public struct PlaceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    
    @Bindable var place: Place
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var copiedCoords = false
    
    public init(place: Place) {
        self.place = place
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                headerSection
                
                // Action Buttons
                actionsRow
                
                // Provenance & Metadata Card
                metadataCard
                
                // Collections Section
                collectionsSection
                
                // Notes Section
                notesSection
                
                // Source & Discovery Link
                if let sourceURL = place.sourceURL, !sourceURL.isEmpty {
                    sourceSection(url: sourceURL)
                }
                
                // Delete Button
                deleteSection
            }
            .padding(16)
        }
        .background(WaypointsColors.sandLight.ignoresSafeArea())
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
                .fontWeight(.semibold)
                .foregroundStyle(WaypointsColors.deepForest)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPlaceSheet(place: place)
        }
        .alert("Delete Waypoint", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deletePlace()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(place.name)'? This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(WaypointsTypography.display(26))
                        .foregroundStyle(WaypointsColors.deepForest)
                    
                    if !place.country.isEmpty {
                        Text(place.country)
                            .font(WaypointsTypography.title(16))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        place.isFavorite.toggle()
                        place.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: place.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 20))
                            .foregroundStyle(place.isFavorite ? WaypointsColors.sunsetAmber : .secondary)
                    }
                    
                    Button {
                        place.isVisited.toggle()
                        place.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: place.isVisited ? "checkmark.seal.fill" : "checkmark.seal")
                            .font(.system(size: 20))
                            .foregroundStyle(place.isVisited ? WaypointsColors.deepForest : .secondary)
                    }
                }
            }
            
            // Coordinate badge with copy
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(WaypointsColors.terracotta)
                Text(place.formattedCoordinates)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                Button {
                    UIPasteboard.general.string = "\(place.latitude),\(place.longitude)"
                    copiedCoords = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        copiedCoords = false
                    }
                } label: {
                    Image(systemName: copiedCoords ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(copiedCoords ? .green : WaypointsColors.deepForest)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var actionsRow: some View {
        HStack(spacing: 12) {
            Button {
                openInMaps()
            } label: {
                Label("Open in Apple Maps", systemName: "map.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(WaypointsColors.deepForest)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let sourceURL = place.sourceURL, let url = URL(string: sourceURL) {
                Button {
                    openURL(url)
                } label: {
                    Label("Source Link", systemName: "arrow.up.right.square")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(WaypointsColors.deepForest)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(WaypointsColors.deepForest.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waypoint Provenance")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WaypointsColors.deepForest)
            
            HStack {
                Label(place.provenance.displayLabel, systemName: place.provenance.systemIcon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WaypointsColors.deepForest)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(WaypointsColors.mintMist)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("Precision: \(place.precision.capitalized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !place.evidence.isEmpty {
                Text("Evidence: \(place.evidence)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Created: \(place.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Updated: \(place.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Collections")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WaypointsColors.deepForest)
            
            if place.collections.isEmpty {
                Text("Not assigned to any collections")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(place.collections) { col in
                            HStack(spacing: 6) {
                                Image(systemName: col.systemIcon)
                                    .foregroundStyle(Color(hex: col.colorHex))
                                Text(col.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(WaypointsColors.deepForest)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: col.colorHex).opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes & Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WaypointsColors.deepForest)
            
            if place.note.isEmpty {
                Text("No notes added yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                Text(place.note)
                    .font(.system(size: 15))
                    .foregroundStyle(WaypointsColors.deepForest)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func sourceSection(url: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Original Source")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text(url)
                .font(.caption)
                .foregroundStyle(WaypointsColors.deepForest)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var deleteSection: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Spacer()
                Image(systemName: "trash")
                Text("Delete Waypoint")
                Spacer()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.red)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.top, 10)
    }
    
    private func openInMaps() {
        let lat = place.latitude
        let lon = place.longitude
        let name = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Waypoint"
        if let url = URL(string: "http://maps.apple.com/?ll=\(lat),\(lon)&q=\(name)") {
            openURL(url)
        }
    }
    
    private func deletePlace() {
        modelContext.delete(place)
        try? modelContext.save()
        dismiss()
    }
}
