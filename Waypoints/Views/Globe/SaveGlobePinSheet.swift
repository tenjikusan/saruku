import SwiftUI
import SwiftData

public struct SaveGlobePinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionModel.name) private var collections: [CollectionModel]
    
    public let latitude: Double
    public let longitude: Double
    
    @State private var name: String = ""
    @State private var country: String = ""
    @State private var note: String = ""
    @State private var selectedCollectionIds: Set<String> = []
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Globe Pin Location") {
                    HStack {
                        Text("Coordinates")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.4f°, %.4f°", latitude, longitude))
                            .font(.system(size: 14, design: .monospaced))
                    }
                    Text("Inverse orthographic projection via tap")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Place Details") {
                    TextField("Place name", text: $name)
                    TextField("Country / Region (optional)", text: $country)
                }
                
                if !collections.isEmpty {
                    Section("Collections") {
                        ForEach(collections) { col in
                            HStack {
                                Image(systemName: col.systemIcon)
                                    .foregroundStyle(Color(hex: col.colorHex))
                                Text(col.name)
                                Spacer()
                                if selectedCollectionIds.contains(col.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(WaypointsColors.deepForest)
                                        .fontWeight(.semibold)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedCollectionIds.contains(col.id) {
                                    selectedCollectionIds.remove(col.id)
                                } else {
                                    selectedCollectionIds.insert(col.id)
                                }
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Save Waypoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Pin") {
                        savePin()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func savePin() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let place = Place(
            name: trimmedName,
            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude,
            longitude: longitude,
            precision: "exact",
            provenance: .globeTap,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            source: "Globe tap",
            evidence: "Manual tap on 3D Earth globe"
        )
        
        place.collections = collections.filter { selectedCollectionIds.contains($0.id) }
        modelContext.insert(place)
        try? modelContext.save()
        dismiss()
    }
}
