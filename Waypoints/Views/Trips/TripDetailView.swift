import SwiftUI
import SwiftData

public struct TripDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var trip: Trip
    @Query(sort: \Place.name) private var allPlaces: [Place]
    
    @State private var selectedDayIndex: Int = 0
    @State private var showingAddStopSheet: Bool = false
    @State private var showingAddDaySheet: Bool = false
    @State private var showingEditTripSheet: Bool = false
    @State private var showingDeleteAlert: Bool = false
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    public init(trip: Trip) {
        self.trip = trip
    }
    
    private var sortedDays: [ItineraryDay] {
        trip.days.sorted { $0.dayNumber < $1.dayNumber }
    }
    
    private var currentDay: ItineraryDay? {
        guard !sortedDays.isEmpty, selectedDayIndex < sortedDays.count else { return nil }
        return sortedDays[selectedDayIndex]
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Trip Header Card
                headerCard
                
                // Days Selector Tabs
                daysSelector
                
                // Day Content / Stops
                if let day = currentDay {
                    dayContentSection(day)
                } else {
                    noDaysEmptyState
                }
            }
            .padding(16)
        }
        .background(WaypointsColors.sandLight.ignoresSafeArea())
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddDaySheet = true
                    } label: {
                        Label("Add Itinerary Day", systemName: "calendar.badge.plus")
                    }
                    
                    Button {
                        showingEditTripSheet = true
                    } label: {
                        Label("Edit Trip Details", systemName: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Trip", systemName: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(WaypointsColors.deepForest)
                }
            }
        }
        .sheet(isPresented: $showingAddStopSheet) {
            if let day = currentDay {
                AddItineraryStopSheet(day: day, places: allPlaces)
            }
        }
        .sheet(isPresented: $showingAddDaySheet) {
            AddItineraryDaySheet(trip: trip, nextDayNumber: (trip.days.map { $0.dayNumber }.max() ?? 0) + 1)
        }
        .sheet(isPresented: $showingEditTripSheet) {
            EditTripSheet(trip: trip)
        }
        .alert("Delete Trip", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(trip.name)'? The saved waypoints will not be deleted.")
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(WaypointsTypography.display(24))
                        .foregroundStyle(WaypointsColors.deepForest)
                    
                    if !trip.destination.isEmpty {
                        Text(trip.destination)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(hex: trip.colorHex))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "airplane")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    )
            }
            
            Divider()
            
            HStack(spacing: 16) {
                Label("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) – \(trip.endDate.formatted(date: .abbreviated, time: .omitted))", systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(trip.durationInDays) Days • \(trip.places.count) Places")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(WaypointsColors.deepForest)
            }
            
            if !trip.tripDescription.isEmpty {
                Text(trip.tripDescription)
                    .font(.subheadline)
                    .foregroundStyle(WaypointsColors.deepForest)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Days Selector Tabs
    
    private var daysSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(sortedDays.enumerated()), id: \.element.id) { index, day in
                    let isSelected = selectedDayIndex == index
                    Button {
                        hapticFeedback.impactOccurred()
                        withAnimation { selectedDayIndex = index }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Day \(day.dayNumber)")
                                .font(.system(size: 13, weight: .bold))
                            if !day.title.isEmpty {
                                Text(day.title)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? WaypointsColors.deepForest : Color.white)
                        .foregroundStyle(isSelected ? .white : WaypointsColors.deepForest)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                    }
                }
                
                // Add Day Button
                Button {
                    showingAddDaySheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundStyle(WaypointsColors.deepForest)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                }
            }
        }
    }
    
    // MARK: - Day Content Section
    
    private func dayContentSection(_ day: ItineraryDay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(day.dayNumber): \(day.title)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(WaypointsColors.deepForest)
                    
                    if let date = day.date {
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    showingAddStopSheet = true
                } label: {
                    Label("Add Stop", systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WaypointsColors.deepForest)
                }
            }
            
            if !day.notes.isEmpty {
                Text(day.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Stops List
            if day.stops.isEmpty {
                VStack(spacing: 8) {
                    Text("No stops planned for Day \(day.dayNumber) yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        showingAddStopSheet = true
                    } label: {
                        Text("Add first destination")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(WaypointsColors.deepForest)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                let sortedStops = day.sortedStops
                ForEach(Array(sortedStops.enumerated()), id: \.element.id) { idx, stop in
                    stopRow(stop: stop, index: idx + 1)
                    
                    // Show real Haversine distance to next stop
                    if idx < sortedStops.count - 1 {
                        let nextStop = sortedStops[idx + 1]
                        if stop.latitude != 0 && stop.longitude != 0 && nextStop.latitude != 0 && nextStop.longitude != 0 {
                            let distKm = CoordinateMath.haversineDistanceKm(
                                lat1: stop.latitude, lon1: stop.longitude,
                                lat2: nextStop.latitude, lon2: nextStop.longitude
                            )
                            HStack(spacing: 6) {
                                Rectangle()
                                    .fill(WaypointsColors.deepForest.opacity(0.2))
                                    .frame(width: 2, height: 16)
                                    .padding(.leading, 18)
                                
                                Text(String(format: "%.1f km to next stop", distKm))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func stopRow(stop: ItineraryStop, index: Int) -> some View {
        HStack(spacing: 12) {
            // Stop number / completion checkmark
            Button {
                hapticFeedback.impactOccurred()
                stop.isCompleted.toggle()
                stop.updatedAt = Date()
                try? modelContext.save()
            } label: {
                ZStack {
                    Circle()
                        .fill(stop.isCompleted ? WaypointsColors.deepForest : WaypointsColors.mintMist)
                        .frame(width: 36, height: 36)
                    
                    if stop.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(index)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(WaypointsColors.deepForest)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(stop.placeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WaypointsColors.deepForest)
                    .strikethrough(stop.isCompleted)
                
                HStack(spacing: 8) {
                    if !stop.scheduledTime.isEmpty {
                        Label(stop.scheduledTime, systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(WaypointsColors.terracotta)
                    }
                    
                    if !stop.notes.isEmpty {
                        Text(stop.notes)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Button {
                if let idx = stop.day?.stops.firstIndex(where: { $0.id == stop.id }) {
                    stop.day?.stops.remove(at: idx)
                    modelContext.delete(stop)
                    try? modelContext.save()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
    
    private var noDaysEmptyState: some View {
        VStack(spacing: 12) {
            Text("No itinerary days added.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Add Day 1") {
                showingAddDaySheet = true
            }
            .fontWeight(.semibold)
            .foregroundStyle(WaypointsColors.deepForest)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Helper Sheets

struct AddItineraryStopSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let day: ItineraryDay
    let places: [Place]
    
    @State private var placeName = ""
    @State private var scheduledTime = ""
    @State private var notes = ""
    @State private var selectedPlaceId: String? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                if !places.isEmpty {
                    Section("Pick from Saved Waypoints") {
                        Picker("Select Waypoint", selection: $selectedPlaceId) {
                            Text("None (Custom Name)").tag(nil as String?)
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
                }
                
                Section("Stop Details") {
                    TextField("Destination / Landmark Name", text: $placeName)
                    TextField("Intended Time (e.g. 10:30 AM)", text: $scheduledTime)
                    TextField("Notes for this stop", text: $notes)
                }
            }
            .navigationTitle("Add Itinerary Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        
                        var lat = 0.0
                        var lon = 0.0
                        if let selectedPlaceId, let found = places.first(where: { $0.id == selectedPlaceId }) {
                            lat = found.latitude
                            lon = found.longitude
                        }
                        
                        let stop = ItineraryStop(
                            sortOrder: day.stops.count + 1,
                            placeName: trimmed,
                            notes: notes,
                            scheduledTime: scheduledTime,
                            latitude: lat,
                            longitude: lon,
                            placeId: selectedPlaceId
                        )
                        stop.day = day
                        day.stops.append(stop)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct AddItineraryDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    let nextDayNumber: Int
    
    @State private var title = ""
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Day Information") {
                    Text("Day \(nextDayNumber)")
                        .fontWeight(.semibold)
                    TextField("Title (e.g. Kyoto Temples)", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes for this day", text: $notes)
                }
            }
            .navigationTitle("Add Day \(nextDayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let day = ItineraryDay(
                            dayNumber: nextDayNumber,
                            title: title.isEmpty ? "Day \(nextDayNumber)" : title,
                            date: date,
                            notes: notes
                        )
                        day.trip = trip
                        trip.days.append(day)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: Trip
    
    @State private var name: String
    @State private var destination: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var description: String
    
    public init(trip: Trip) {
        self.trip = trip
        _name = State(initialValue: trip.name)
        _destination = State(initialValue: trip.destination)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _description = State(initialValue: trip.tripDescription)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Information") {
                    TextField("Trip Name", text: $name)
                    TextField("Main Destination", text: $destination)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        trip.name = name
                        trip.destination = destination
                        trip.startDate = startDate
                        trip.endDate = endDate
                        trip.tripDescription = description
                        trip.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
