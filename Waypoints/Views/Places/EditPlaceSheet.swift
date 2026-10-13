import SwiftUI
import SwiftData

public struct EditPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionModel.name) private var availableCollections: [CollectionModel]
    
    @Bindable var place: Place
    
    @State private var name: String
    @State private var country: String
    @State private var latitudeString: String
    @State private var longitudeString: String
    @State private var note: String
    @State private var isFavorite: Bool
    @State private var isVisited: Bool
    @State private var selectedCollectionIds: Set<String>
    @State private var errorMessage: String?
    
    public init(place: Place) {
        self.place = place
        _name = State(initialValue: place.name)
        _country = State(initialValue: place.country)
        _latitudeString = State(initialValue: String(format: "%.6f", place.latitude))
        _longitudeString = State(initialValue: String(format: "%.6f", place.longitude))
        _note = State(initialValue: place.note)
        _isFavorite = State(initialValue: place.isFavorite)
        _isVisited = State(initialValue: place.isVisited)
        _selectedCollectionIds = State(initialValue: Set(place.collections.map { $0.id }))
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Place name", text: $name)
                    TextField("Country / Region", text: $country)
                }
                
                Section("Coordinates") {
                    HStack {
                        Text("Latitude")
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("-90.0 to 90.0", text: $latitudeString)
                            .keyboardType(.numbersAndPunctuation)
                    }
                    HStack {
                        Text("Longitude")
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField("-180.0 to 180.0", text: $longitudeString)
                            .keyboardType(.numbersAndPunctuation)
                    }
                    Text("Provenance: \(place.provenance.displayLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Collections") {
                    if availableCollections.isEmpty {
                        Text("No collections available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableCollections) { col in
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
                
                Section("Status") {
                    Toggle("Mark as Favorite", isOn: $isFavorite)
                    Toggle("Mark as Visited", isOn: $isVisited)
                }
                
                Section("Personal Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Place name cannot be empty."
            return
        }
        
        let valResult = CoordinateValidator.validateString(latitude: latitudeString, longitude: longitudeString)
        guard valResult.isValid, let lat = valResult.latitude, let lon = valResult.longitude else {
            errorMessage = valResult.errorMessage ?? "Invalid coordinates entered."
            return
        }
        
        place.name = trimmedName
        place.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        place.latitude = lat
        place.longitude = lon
        place.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        place.isFavorite = isFavorite
        place.isVisited = isVisited
        place.updatedAt = Date()
        
        // Update collections
        place.collections = availableCollections.filter { selectedCollectionIds.contains($0.id) }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save place: \(error.localizedDescription)"
        }
    }
}
