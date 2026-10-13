import SwiftUI
import SwiftData
import UniformTypeIdentifiers

public struct BackupRestoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [Place]
    @Query private var discoveries: [Discovery]
    @Query private var collections: [CollectionModel]
    @Query private var trips: [Trip]
    @Query private var journalEntries: [JournalEntry]
    
    @State private var importMode: LegacyBackupImporter.ImportMode = .merge
    @State private var showingFileImporter = false
    @State private var showingExportShareSheet = false
    @State private var exportedDataString: String? = nil
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var isProcessing = false
    
    public init() {}
    
    public var body: some View {
        List {
            Section("Export Waypoints Data") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Export your waypoints, discoveries, and collections to a standardized JSON backup file.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(places.count) waypoints • \(discoveries.count) discoveries • \(collections.count) collections")
                        .font(.caption)
                        .foregroundStyle(WaypointsColors.deepForest)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
                
                Button {
                    exportBackup()
                } label: {
                    Label("Export Backup File", systemName: "square.and.arrow.up")
                        .fontWeight(.medium)
                }
                .disabled(isProcessing)
            }
            
            Section("Import Data") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Restore or import places from a previous Waypoints backup or legacy web archive.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
                Picker("Import Mode", selection: $importMode) {
                    Text("Merge (Keep Existing)").tag(LegacyBackupImporter.ImportMode.merge)
                    Text("Replace All").tag(LegacyBackupImporter.ImportMode.replace)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
                
                if importMode == .replace {
                    Text("Warning: Replace mode will permanently delete your existing waypoints and discoveries before importing.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Button {
                    showingFileImporter = true
                } label: {
                    Label("Select JSON Backup File", systemName: "folder")
                        .fontWeight(.medium)
                }
                .disabled(isProcessing)
            }
            
            Section("Data Safety & Validation") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(WaypointsColors.deepForest)
                        Text("Strict Coordinate Validation")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text("Coordinates are strictly verified. Null, empty, or missing values are never coerced to (0,0) (Null Island). Invalid records are safely skipped with detailed counts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Backup & Restore")
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.json, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .sheet(isPresented: $showingExportShareSheet) {
            if let exportedDataString {
                ShareFileView(content: exportedDataString, filename: "waypoints_backup_\(dateString()).json")
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportBackup() {
        isProcessing = true
        do {
            let json = try NativeBackupService.exportBackup(
                places: places,
                discoveries: discoveries,
                collections: collections,
                trips: trips,
                journalEntries: journalEntries
            )
            self.exportedDataString = json
            self.showingExportShareSheet = true
        } catch {
            alertTitle = "Export Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        isProcessing = false
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        isProcessing = true
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            
            guard selectedURL.startAccessingSecurityScopedResource() else {
                alertTitle = "Permission Denied"
                alertMessage = "Unable to read the selected file due to security scope restrictions."
                showingAlert = true
                isProcessing = false
                return
            }
            
            defer { selectedURL.stopAccessingSecurityScopedResource() }
            
            do {
                let fileData = try Data(contentsOf: selectedURL)
                guard let jsonString = String(data: fileData, encoding: .utf8) else {
                    throw ImportError.invalidData("Selected file is not valid UTF-8 text.")
                }
                
                let importResult = try LegacyBackupImporter.parseAndImport(
                    jsonString: jsonString,
                    mode: importMode,
                    context: modelContext
                )
                
                alertTitle = "Import Complete"
                alertMessage = importResult.summaryMessage
                showingAlert = true
            } catch {
                alertTitle = "Import Failed"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            
        case .failure(let error):
            alertTitle = "Import Error"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        isProcessing = false
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

public struct ShareFileView: UIViewControllerRepresentable {
    public let content: String
    public let filename: String
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.data(using: .utf8)?.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
