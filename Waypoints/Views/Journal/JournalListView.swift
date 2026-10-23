import SwiftUI
import SwiftData
import PhotosUI

public struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.visitDate, order: .reverse) private var entries: [JournalEntry]
    @Query private var places: [Place]
    @Query private var trips: [Trip]
    @Query private var collections: [CollectionModel]
    
    @State private var showingAddEntrySheet = false
    
    public init() {}
    
    private var totalVisitedPlaces: Int {
        places.filter { $0.isVisited }.count
    }
    
    private var uniqueCountriesVisited: Int {
        let visitedCountries = places
            .filter { $0.isVisited }
            .map { $0.country.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(visitedCountries).count
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Travel Statistics Header
                    travelStatsHeader
                    
                    // Timeline of Journal Entries
                    if entries.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(entries) { entry in
                                journalEntryCard(entry)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(WaypointsColors.background.ignoresSafeArea())
            .navigationTitle("Travel Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddEntrySheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddEntrySheet) {
                AddJournalEntrySheet(places: places, trips: trips)
            }
        }
    }
    
    // MARK: - Travel Statistics
    
    private var travelStatsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PASSPORT STATS")
                .font(WaypointsTypography.eyebrow)
                .foregroundStyle(WaypointsColors.textSecondary)
            
            HStack(spacing: 12) {
                statBox(title: "Visited", value: "\(totalVisitedPlaces)", icon: "checkmark.seal.fill")
                statBox(title: "Countries", value: "\(uniqueCountriesVisited)", icon: "globe.americas.fill")
                statBox(title: "Journal Entries", value: "\(entries.count)", icon: "book.fill")
            }
            
            HStack(spacing: 12) {
                statBox(title: "Trips Planned", value: "\(trips.count)", icon: "airplane")
                statBox(title: "Saved Spots", value: "\(places.count)", icon: "mappin.circle.fill")
                statBox(title: "Favorites", value: "\(places.filter { $0.isFavorite }.count)", icon: "star.fill")
            }
        }
        .padding(16)
        .background(WaypointsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WaypointsColors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func statBox(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(WaypointsColors.brandPrimary)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(WaypointsColors.textSecondary)
            }
            Text(value)
                .font(WaypointsTypography.display(20))
                .foregroundStyle(WaypointsColors.brandPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(WaypointsColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(WaypointsColors.border, lineWidth: 1))
    }
    
    // MARK: - Journal Entry Card
    
    private func journalEntryCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.placeName.isEmpty ? entry.title : entry.placeName)
                        .font(WaypointsTypography.display(18))
                        .foregroundStyle(WaypointsColors.textPrimary)
                    
                    Text(entry.visitDate.formatted(date: .long, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(WaypointsColors.textSecondary)
                }
                
                Spacer()
                
                // Star Rating Display
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= entry.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(star <= entry.rating ? Color(hex: "#E09F3E") : WaypointsColors.border)
                    }
                }
            }
            
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.system(size: 14))
                    .foregroundStyle(WaypointsColors.textPrimary)
                    .lineLimit(4)
            }
            
            // Attached Images Thumbnails
            if !entry.imageFileNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.imageFileNames, id: \.self) { fileName in
                            if let img = LocalMediaStorage.shared.loadImage(fileName: fileName) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(WaypointsColors.border, lineWidth: 1))
                            }
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
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "book.pages")
                .font(.system(size: 52))
                .foregroundStyle(WaypointsColors.brandPrimary.opacity(0.3))
            
            Text("No Journal Entries Yet")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.textPrimary)
            
            Text("Keep a private record of your travels, memories, ratings, and visited destination photos.")
                .font(.subheadline)
                .foregroundStyle(WaypointsColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingAddEntrySheet = true
            } label: {
                Label("Add First Entry", systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(WaypointsColors.brandPrimary)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Add Journal Entry Sheet

public struct AddJournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    public let places: [Place]
    public let trips: [Trip]
    
    @State private var title = ""
    @State private var placeName = ""
    @State private var selectedPlaceId: String? = nil
    @State private var selectedTripId: String? = nil
    @State private var note = ""
    @State private var visitDate = Date()
    @State private var rating = 5
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var savedImageFileNames: [String] = []
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Visited Destination") {
                    if !places.isEmpty {
                        Picker("Select Saved Waypoint", selection: $selectedPlaceId) {
                            Text("Custom Location").tag(nil as String?)
                            ForEach(places) { p in
                                Text(p.name).tag(p.id as String?)
                            }
                        }
                        .onChange(of: selectedPlaceId) { _, id in
                            if let id, let found = places.first(where: { $0.id == id }) {
                                placeName = found.name
                            }
                        }
                    }
                    
                    TextField("Destination / Place Name", text: $placeName)
                }
                
                Section("Visit Date & Rating") {
                    DatePicker("Date Visited", selection: $visitDate, displayedComponents: .date)
                    
                    Stepper("Rating: \(rating) Stars", value: $rating, in: 1...5)
                }
                
                if !trips.isEmpty {
                    Section("Associated Trip (Optional)") {
                        Picker("Trip", selection: $selectedTripId) {
                            Text("None").tag(nil as String?)
                            ForEach(trips) { t in
                                Text(t.name).tag(t.id as String?)
                            }
                        }
                    }
                }
                
                Section("Memories & Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
                
                Section("Photos") {
                    let photoLabelText = savedImageFileNames.isEmpty ? "Attach Photos" : "\(savedImageFileNames.count) Photos Attached"
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label(photoLabelText, systemImage: "photo.badge.plus")
                    }
                    .onChange(of: selectedPhotoItems) { _, items in
                        loadPhotos(items)
                    }
                }
            }
            .navigationTitle("New Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Entry") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .disabled(placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func loadPhotos(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let fileName = LocalMediaStorage.shared.saveImageData(data) {
                    await MainActor.run {
                        if !savedImageFileNames.contains(fileName) {
                            savedImageFileNames.append(fileName)
                        }
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        let trimmedPlace = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPlace.isEmpty else { return }
        
        let entry = JournalEntry(
            title: trimmedPlace,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            visitDate: visitDate,
            rating: rating,
            imageFileNames: savedImageFileNames,
            tripId: selectedTripId,
            placeId: selectedPlaceId,
            placeName: trimmedPlace
        )
        
        // Also mark the place as visited if linked
        if let selectedPlaceId, let place = places.first(where: { $0.id == selectedPlaceId }) {
            place.isVisited = true
            entry.place = place
        }
        
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}
