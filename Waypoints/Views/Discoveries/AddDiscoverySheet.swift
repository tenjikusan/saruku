import SwiftUI
import PhotosUI

public struct AddDiscoverySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    
    public var onSave: (String, String, String, [String]) -> Void
    
    @State private var urlText: String = ""
    @State private var captionText: String = ""
    @State private var selectedCollection: String = "Dream trips"
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var savedImageFileNames: [String] = []
    @State private var isRunningOCR: Bool = false
    @State private var ocrNotice: String? = nil
    @State private var errorMessage: String? = nil
    @State private var isBatchMode: Bool = false
    @State private var batchText: String = ""
    
    private let availableCollections = ["Dream trips", "Hidden gems", "Food & cafes", "Scenic viewpoints", "Beaches", "Historic Sites"]
    
    public init(onSave: @escaping (String, String, String, [String]) -> Void) {
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Mode Toggle (Single Entry vs Batch Import)
                    Picker("Input Mode", selection: $isBatchMode) {
                        Text("Single Destination").tag(false)
                        Text("Batch Import (Multiple)").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    if isBatchMode {
                        batchImportSection
                    } else {
                        singleImportSection
                    }
                    
                    // Screenshot / Image Attachments (Multi-photo supported)
                    imageAttachmentsSection
                    
                    // Collection Selector
                    collectionSelectorSection
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(WaypointsTypography.caption)
                            .foregroundColor(.red)
                    }
                    
                    // Save Button
                    PrimaryButton(isBatchMode ? "Batch Import Destinations" : "Save to Discoveries Inbox") {
                        handleSave()
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(WaypointsTheme.background(for: scheme).ignoresSafeArea())
            .navigationTitle(isBatchMode ? "Batch Import" : "Add Discovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(Color.waypointsGreen)
                }
            }
        }
    }
    
    private var singleImportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paste any link from Instagram, TikTok, YouTube, X, Google Maps, Apple Maps, or a travel article.")
                .font(WaypointsTypography.body)
                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("POST OR WEBPAGE LINK")
                    .font(WaypointsTypography.eyebrow)
                    .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                
                TextField("https://instagram.com/p/... or https://maps.apple.com/...", text: $urlText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .padding(12)
                    .background(WaypointsTheme.surface(for: scheme))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("CAPTION, PLACE NAME, OR NOTES")
                    .font(WaypointsTypography.eyebrow)
                    .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                
                TextField("e.g. 5 great spots in Kyoto: Fushimi Inari, Kinkaku-ji, Arashiyama, Gion, Kiyomizu-dera", text: $captionText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(WaypointsTheme.surface(for: scheme))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
                
                Text("Tip: You can list multiple places separated by commas, bullets, or numbers. Waypoints will extract all of them.")
                    .font(WaypointsTypography.caption)
                    .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
            }
        }
    }
    
    private var batchImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paste multiple links or a list of destinations (one per line). Waypoints will queue them for identification.")
                .font(WaypointsTypography.body)
                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
            
            TextEditor(text: $batchText)
                .frame(minHeight: 140)
                .padding(8)
                .background(WaypointsTheme.surface(for: scheme))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
            
            Text("Example:\nhttps://maps.apple.com/?ll=35.0,135.7\nLake Como, Italy\nSantorini Caldera, Greece")
                .font(WaypointsTypography.caption)
                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
        }
    }
    
    private var imageAttachmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ATTACH SCREENSHOTS OR PHOTOS (OPTIONAL)")
                .font(WaypointsTypography.eyebrow)
                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
            
            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: 8,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                    Text(savedImageFileNames.isEmpty ? "Select Photos or Screenshots" : "Add More Images (\(savedImageFileNames.count) attached)")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(WaypointsTheme.surface(for: scheme))
                .foregroundColor(Color.waypointsGreen)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
            }
            .onChange(of: selectedPhotoItems) { _, items in
                processSelectedPhotos(items)
            }
            
            if isRunningOCR {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Color.waypointsGreen)
                    Text("Scanning images with Apple Vision OCR & EXIF GPS…")
                        .font(WaypointsTypography.caption)
                        .foregroundColor(Color.waypointsGreen)
                }
            }
            
            if let notice = ocrNotice {
                Text(notice)
                    .font(WaypointsTypography.caption)
                    .foregroundColor(Color.waypointsGreen)
            }
            
            if !savedImageFileNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(savedImageFileNames, id: \.self) { fileName in
                            if let uiImg = LocalMediaStorage.shared.loadImage(fileName: fileName) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    
                                    Button {
                                        removeImage(fileName)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.red)
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
    }
    
    private var collectionSelectorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TARGET COLLECTION")
                .font(WaypointsTypography.eyebrow)
                .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
            
            Picker("Collection", selection: $selectedCollection) {
                ForEach(availableCollections, id: \.self) { col in
                    Text(col).tag(col)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.waypointsGreen)
        }
    }
    
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isRunningOCR = true
        ocrNotice = nil
        
        Task {
            var extractedTexts: [String] = []
            var foundGPSCount = 0
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    // Check EXIF GPS
                    if let _ = ImageMetadataExtractor.extractGPSCoordinates(from: data) {
                        foundGPSCount += 1
                    }
                    
                    // Save to durable local storage
                    if let savedName = LocalMediaStorage.shared.saveImageData(data) {
                        await MainActor.run {
                            if !savedImageFileNames.contains(savedName) {
                                savedImageFileNames.append(savedName)
                            }
                        }
                    }
                    
                    // Run Apple Vision OCR
                    if let img = UIImage(data: data) {
                        let res = await VisionOCRService.shared.recognizeText(in: img)
                        if !res.recognizedText.isEmpty {
                            extractedTexts.append(res.recognizedText)
                        }
                    }
                }
            }
            
            await MainActor.run {
                isRunningOCR = false
                if !extractedTexts.isEmpty {
                    let combined = extractedTexts.joined(separator: "\n")
                    if captionText.isEmpty {
                        captionText = combined
                    } else {
                        captionText += "\n" + combined
                    }
                    ocrNotice = "Extracted text from \(extractedTexts.count) image(s)."
                }
                if foundGPSCount > 0 {
                    ocrNotice = (ocrNotice ?? "") + " Found embedded camera GPS metadata in \(foundGPSCount) photo(s)."
                }
            }
        }
    }
    
    private func removeImage(_ fileName: String) {
        savedImageFileNames.removeAll(where: { $0 == fileName })
        LocalMediaStorage.shared.deleteImage(fileName: fileName)
    }
    
    private func handleSave() {
        if isBatchMode {
            let lines = batchText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            guard !lines.isEmpty else {
                errorMessage = "Please enter at least one URL or destination name."
                return
            }
            
            for line in lines {
                let isURL = line.lowercased().hasPrefix("http")
                let url = isURL ? line : ""
                let caption = isURL ? "" : line
                onSave(url, caption, selectedCollection, [])
            }
            dismiss()
        } else {
            let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCaption = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedURL.isEmpty || !trimmedCaption.isEmpty || !savedImageFileNames.isEmpty else {
                errorMessage = "Please provide at least a link, caption, or screenshot."
                return
            }
            
            onSave(trimmedURL, trimmedCaption, selectedCollection, savedImageFileNames)
            dismiss()
        }
    }
}
