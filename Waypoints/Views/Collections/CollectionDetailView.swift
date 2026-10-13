import SwiftUI
import SwiftData

public struct CollectionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var collection: CollectionModel
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    public init(collection: CollectionModel) {
        self.collection = collection
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header card
            headerCard
            
            // Places in collection
            if collection.places.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(collection.places) { place in
                        NavigationLink {
                            PlaceDetailView(place: place)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(WaypointsColors.deepForest)
                                    if !place.country.isEmpty {
                                        Text(place.country)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(place.formattedCoordinates)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if place.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(WaypointsColors.sunsetAmber)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                removePlace(place)
                            } label: {
                                Label("Remove", systemName: "minus.circle")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(WaypointsColors.sandLight)
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Collection", systemName: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Collection", systemName: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCollectionSheet(collection: collection)
        }
        .alert("Delete Collection", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteCollection()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(collection.name)'? The saved waypoints will not be deleted.")
        }
    }
    
    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: collection.colorHex).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: collection.systemIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: collection.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(WaypointsTypography.display(20))
                    .foregroundStyle(WaypointsColors.deepForest)
                Text("\(collection.places.count) saved waypoint\(collection.places.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: collection.colorHex).opacity(0.4))
            Text("No Waypoints in this Collection")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.deepForest)
            Text("Assign waypoints to this collection when confirming discoveries or editing a waypoint.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    private func removePlace(_ place: Place) {
        if let idx = collection.places.firstIndex(where: { $0.id == place.id }) {
            collection.places.remove(at: idx)
            try? modelContext.save()
        }
    }
    
    private func deleteCollection() {
        modelContext.delete(collection)
        try? modelContext.save()
        dismiss()
    }
}

public struct EditCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var collection: CollectionModel
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColorHex: String
    
    let icons = ["folder.fill", "star.fill", "heart.fill", "airplane", "tent.fill", "cup.and.saucer.fill", "camera.fill", "figure.walk", "mountain.2.fill", "water.waves"]
    let colors = ["#244B3B", "#B27C61", "#D97447", "#5B8E7D", "#8C6A58", "#386641", "#6A994E", "#BC4749"]
    
    public init(collection: CollectionModel) {
        self.collection = collection
        _name = State(initialValue: collection.name)
        _selectedIcon = State(initialValue: collection.systemIcon)
        _selectedColorHex = State(initialValue: collection.colorHex)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Collection Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : Color.clear)
                                    .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(selectedColorHex == hex ? 0.4 : 0), lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            collection.name = trimmed
                            collection.systemIcon = selectedIcon
                            collection.colorHex = selectedColorHex
                            try? modelContext.save()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
