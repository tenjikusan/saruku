import SwiftUI
import SwiftData

public struct TripsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    
    @State private var showingCreateTripSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                if trips.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(trips) { trip in
                            NavigationLink {
                                TripDetailView(trip: trip)
                            } label: {
                                tripCard(trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .background(WaypointsColors.background.ignoresSafeArea())
            .navigationTitle("Trips & Itineraries")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTripSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(WaypointsColors.brandPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateTripSheet) {
                CreateTripSheet()
            }
        }
    }
    
    private func tripCard(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(WaypointsTypography.display(20))
                        .foregroundStyle(WaypointsColors.textPrimary)
                    
                    if !trip.destination.isEmpty {
                        Text(trip.destination)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(WaypointsColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(hex: trip.colorHex))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "airplane")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    )
            }
            
            Divider()
            
            HStack {
                Label("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) – \(trip.endDate.formatted(date: .abbreviated, time: .omitted))", systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(WaypointsColors.textSecondary)
                
                Spacer()
                
                Text("\(trip.durationInDays) Days • \(trip.days.count) Days Planned")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(WaypointsColors.brandPrimary)
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
            Spacer().frame(height: 80)
            Image(systemName: "airplane.circle")
                .font(.system(size: 54))
                .foregroundStyle(WaypointsColors.brandPrimary.opacity(0.3))
            
            Text("No Trips Planned Yet")
                .font(WaypointsTypography.title(18))
                .foregroundStyle(WaypointsColors.textPrimary)
            
            Text("Create multi-day trip itineraries, organize daily stops, and visualize your journeys on the globe.")
                .font(.subheadline)
                .foregroundStyle(WaypointsColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingCreateTripSheet = true
            } label: {
                Label("Plan a Trip", systemName: "plus")
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

public struct CreateTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var description = ""
    @State private var colorHex = "#244B3B"
    @State private var errorMessage: String?
    
    let colors = ["#244B3B", "#B27C61", "#D97447", "#5B8E7D", "#8C6A58", "#386641", "#6A994E", "#BC4749"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Trip Information") {
                    TextField("Trip Name (e.g. Japan 2027, Europe Summer)", text: $name)
                    TextField("Destination (e.g. Kyoto & Tokyo, Japan)", text: $destination)
                }
                
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Theme Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(colorHex == hex ? 0.4 : 0), lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Notes & Description") {
                    TextField("Optional trip notes", text: $description)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            errorMessage = "Please enter a trip name."
                            return
                        }
                        
                        let trip = Trip(
                            name: trimmed,
                            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
                            startDate: startDate,
                            endDate: endDate,
                            tripDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
                            colorHex: colorHex
                        )
                        
                        // Automatically bootstrap Day 1
                        let day1 = ItineraryDay(dayNumber: 1, title: "Day 1", date: startDate)
                        day1.trip = trip
                        trip.days.append(day1)
                        
                        modelContext.insert(trip)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
