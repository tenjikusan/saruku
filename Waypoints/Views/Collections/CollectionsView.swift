import SwiftUI
import SwiftData

public struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionModel.createdAt) private var collections: [CollectionModel]
    
    @State private var showingAddCollectionSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                if collections.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(collections) { collection in
                            NavigationLink {
                                CollectionDetailView(collection: collection)
                            } label: {
                                collectionCard(collection)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .background(WaypointsColors.sandLight.ignoresSafeArea())
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddCollectionSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddCollectionSheet) {
                AddCollectionSheet()
            }
        }
    }
    
    private func collectionCard(_ collection: CollectionModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: collection.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: collection.systemIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: collection.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WaypointsColors.deepForest)
                    .lineLimit(1)
                
                Text("\(collection.places.count) place\(collection.places.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 54))
                .foregroundStyle(WaypointsColors.deepForest.opacity(0.3))
            
            Text("No Collections")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.deepForest)
            
            Text("Organize your travel destinations and saved spots by trip, region, or theme.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingAddCollectionSheet = true
            } label: {
                Label("New Collection", systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(WaypointsColors.deepForest)
                    .clipShape(Capsule())
            }
        }
    }
}

public struct AddCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColorHex = "#244B3B"
    @State private var errorMessage: String?
    
    let icons = ["folder.fill", "star.fill", "heart.fill", "airplane", "tent.fill", "cup.and.saucer.fill", "camera.fill", "figure.walk", "mountain.2.fill", "water.waves"]
    let colors = ["#244B3B", "#B27C61", "#D97447", "#5B8E7D", "#8C6A58", "#386641", "#6A994E", "#BC4749"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Collection Name") {
                    TextField("e.g. Kyoto 2026, Summer Lakes", text: $name)
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
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            errorMessage = "Please enter a collection name."
                            return
                        }
                        let col = CollectionModel(
                            name: trimmed,
                            systemIcon: selectedIcon,
                            colorHex: selectedColorHex
                        )
                        modelContext.insert(col)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
