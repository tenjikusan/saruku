import SwiftUI
import SwiftData
import PhotosUI

public struct PlaceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    
    @Bindable var place: Place
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddSourceSheet = false
    @State private var showingShareSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var copiedCoords = false
    @State private var previewImageFileName: String? = nil
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    public init(place: Place) {
        self.place = place
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                headerSection
                
                // Navigation and Share Actions
                actionsRow
                
                // Photo Attachments Section
                photoAttachmentsSection
                
                // Provenance & Metadata Card
                metadataCard
                
                // Collections Section
                collectionsSection
                
                // Notes Section
                notesSection
                
                // Multiple Source References Section
                multipleSourcesSection
                
                // Delete Button
                deleteSection
            }
            .padding(16)
        }
        .background(WaypointsColors.background.ignoresSafeArea())
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Details", systemName: "pencil")
                    }
                    
                    Button {
                        showingAddSourceSheet = true
                    } label: {
                        Label("Attach Source Link", systemName: "link.badge.plus")
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share Place", systemName: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Waypoint", systemName: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(WaypointsColors.brandPrimary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPlaceSheet(place: place)
        }
        .sheet(isPresented: $showingAddSourceSheet) {
            AddSourceReferenceSheet(place: place)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [
                "📍 \(place.name)\n\(place.country.isEmpty ? "" : place.country + "\n")Coordinates: \(place.formattedCoordinates)\n\(place.note.isEmpty ? "" : "\n" + place.note + "\n")Saved with Waypoints"
            ])
        }
        .sheet(item: Binding<PreviewImageItem?>(
            get: { previewImageFileName.map { PreviewImageItem(fileName: $0) } },
            set: { previewImageFileName = $0?.fileName }
        )) { item in
            ImagePreviewModal(fileName: item.fileName)
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(WaypointsTypography.display(26))
                        .foregroundStyle(WaypointsColors.deepForest)
                    
                    let locationSubtitle = [place.city, place.region, place.country].filter { !$0.isEmpty }.joined(separator: ", ")
                    if !locationSubtitle.isEmpty {
                        Text(locationSubtitle)
                            .font(WaypointsTypography.title(16))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        hapticFeedback.impactOccurred()
                        place.isFavorite.toggle()
                        place.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: place.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundStyle(place.isFavorite ? WaypointsColors.sunsetAmber : .secondary)
                    }
                    
                    Button {
                        hapticFeedback.impactOccurred()
                        place.isVisited.toggle()
                        place.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: place.isVisited ? "checkmark.seal.fill" : "checkmark.seal")
                            .font(.system(size: 22))
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
                    hapticFeedback.impactOccurred()
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
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Actions Row
    
    private var actionsRow: some View {
        HStack(spacing: 12) {
            Button {
                openInMaps()
            } label: {
                Label("Apple Maps", systemName: "map.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(WaypointsColors.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button {
                openDirections()
            } label: {
                Label("Directions", systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WaypointsColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(WaypointsColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(WaypointsColors.border, lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Photo Attachments Section
    
    private var photoAttachmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Saved Photos & Screenshots")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WaypointsColors.brandPrimary)
                
                Spacer()
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Add Photo", systemName: "photo.badge.plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WaypointsColors.brandPrimary)
                }
                .onChange(of: selectedPhotoItem) { _, item in
                    if let item {
                        attachPhoto(item)
                    }
                }
            }
            
            if place.imageFileNames.isEmpty {
                Text("No screenshots or photos attached.")
                    .font(.caption)
                    .foregroundStyle(WaypointsColors.textSecondary)
                    .italic()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(place.imageFileNames, id: \.self) { fileName in
                            if let img = LocalMediaStorage.shared.loadImage(fileName: fileName) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsColors.border, lineWidth: 1))
                                        .onTapGesture {
                                            previewImageFileName = fileName
                                        }
                                    
                                    Button {
                                        place.removeImageFileName(fileName)
                                        try? modelContext.save()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.red)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Metadata Card
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waypoint Provenance")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WaypointsColors.brandPrimary)
            
            HStack {
                Label(place.provenance.displayLabel, systemName: place.provenance.systemIcon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WaypointsColors.brandPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(WaypointsColors.brandPrimary.opacity(0.08))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("Precision: \(place.precision.capitalized)")
                    .font(.caption)
                    .foregroundStyle(WaypointsColors.textSecondary)
            }
            
            if !place.evidence.isEmpty {
                Text("Evidence: \(place.evidence)")
                    .font(.caption)
                    .foregroundStyle(WaypointsColors.textSecondary)
            }
            
            HStack {
                Text("Created: \(place.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(WaypointsColors.textSecondary)
                Spacer()
                Text("Updated: \(place.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(WaypointsColors.textSecondary)
            }
        }
        .padding(16)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Collections Section
    
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Collections")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WaypointsColors.brandPrimary)
            
            if place.collections.isEmpty {
                Text("Not assigned to any collections")
                    .font(.subheadline)
                    .foregroundStyle(WaypointsColors.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(place.collections) { col in
                            HStack(spacing: 6) {
                                Image(systemName: col.systemIcon)
                                    .foregroundStyle(Color(hex: col.colorHex))
                                Text(col.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(WaypointsColors.textPrimary)
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
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes & Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WaypointsColors.brandPrimary)
            
            if place.note.isEmpty {
                Text("No notes added yet.")
                    .font(.subheadline)
                    .foregroundStyle(WaypointsColors.textSecondary)
                    .italic()
            } else {
                Text(place.note)
                    .font(.system(size: 15))
                    .foregroundStyle(WaypointsColors.textPrimary)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Multiple Source References Section
    
    private var multipleSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Content Sources")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WaypointsColors.brandPrimary)
                
                Spacer()
                
                Button {
                    showingAddSourceSheet = true
                } label: {
                    Label("Add Source", systemName: "plus")
                        .font(.caption)
                        .foregroundStyle(WaypointsColors.brandPrimary)
                }
            }
            
            // Primary link if available
            if let primary = place.sourceURL, !primary.isEmpty {
                sourceItemRow(url: primary, platform: "Primary Source", title: place.name)
            }
            
            // Multiple source references
            ForEach(place.sourceReferences) { ref in
                sourceItemRow(url: ref.url, platform: ref.platformName, title: ref.title)
            }
            
            if place.sourceURL == nil && place.sourceReferences.isEmpty {
                Text("No external links attached to this waypoint.")
                    .font(.caption)
                    .foregroundStyle(WaypointsColors.textSecondary)
                    .italic()
            }
        }
        .padding(16)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func sourceItemRow(url: String, platform: String, title: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(WaypointsColors.brandPrimary)
                Text(url)
                    .font(.caption2)
                    .foregroundStyle(WaypointsColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let destURL = URL(string: url) {
                Button {
                    openURL(destURL)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 16))
                        .foregroundStyle(WaypointsColors.brandPrimary)
                }
            }
        }
        .padding(8)
        .background(WaypointsColors.brandPrimary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Delete Section
    
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
            .background(WaypointsColors.surface)
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
    
    private func openDirections() {
        let lat = place.latitude
        let lon = place.longitude
        if let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d") {
            openURL(url)
        }
    }
    
    private func attachPhoto(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let savedFileName = LocalMediaStorage.shared.saveImageData(data) {
                await MainActor.run {
                    place.addImageFileName(savedFileName)
                    try? modelContext.save()
                    selectedPhotoItem = nil
                }
            }
        }
    }
    
    private func deletePlace() {
        modelContext.delete(place)
        try? modelContext.save()
        dismiss()
    }
}

// Helper structs for PlaceDetailView
struct PreviewImageItem: Identifiable {
    let id = UUID()
    let fileName: String
}

struct ImagePreviewModal: View {
    @Environment(\.dismiss) private var dismiss
    let fileName: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let img = LocalMediaStorage.shared.loadImage(fileName: fileName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct AddSourceReferenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let place: Place
    
    @State private var url = ""
    @State private var platform = "Instagram"
    @State private var note = ""
    
    let platforms = ["Instagram", "TikTok", "YouTube", "X (Twitter)", "Apple Maps", "Google Maps", "Safari Web", "Blog Post"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Source Details") {
                    Picker("Platform", selection: $platform) {
                        ForEach(platforms, id: \.self) { p in
                            Text(p).tag(p)
                        }
                    }
                    TextField("https://...", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                Section("Description / Title") {
                    TextField("e.g. Travel reel by @explorer", text: $note)
                }
            }
            .navigationTitle("Attach Source Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedURL.isEmpty {
                            let ref = SourceReference(url: trimmedURL, platformName: platform, title: note)
                            place.addSourceReference(ref)
                            try? modelContext.save()
                        }
                        dismiss()
                    }
                    .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
