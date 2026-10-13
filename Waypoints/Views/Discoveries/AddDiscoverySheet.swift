import SwiftUI
import PhotosUI

public struct AddDiscoverySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    
    public var onSave: (String, String, String, Data?) -> Void
    
    @State private var urlText: String = ""
    @State private var captionText: String = ""
    @State private var selectedCollection: String = "Dream trips"
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isRunningOCR: Bool = false
    @State private var ocrNotice: String? = nil
    @State private var errorMessage: String? = nil
    
    private let availableCollections = ["Dream trips", "Good eats", "Into the wild", "City escapes"]
    
    public init(onSave: @escaping (String, String, String, Data?) -> Void) {
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Subtitle
                    Text("Paste any link from Instagram, X, Facebook, or a travel blog. It saves immediately to your inbox.")
                        .font(WaypointsTypography.body)
                        .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                    
                    // 1. Post or Webpage Link
                    VStack(alignment: .leading, spacing: 6) {
                        Text("POST OR WEBPAGE LINK")
                            .font(WaypointsTypography.eyebrow)
                            .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                        
                        TextField("https://instagram.com/p/... or https://maps.google.com/...", text: $urlText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(12)
                            .background(WaypointsTheme.surface(for: scheme))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
                    }
                    
                    // 2. Caption or Place Clue
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CAPTION OR PLACE CLUE (RECOMMENDED)")
                            .font(WaypointsTypography.eyebrow)
                            .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                        
                        TextField("e.g. Fushimi Inari Torii gates in Kyoto, or paste post text with coordinates", text: $captionText, axis: .vertical)
                            .lineLimit(3...5)
                            .padding(12)
                            .background(WaypointsTheme.surface(for: scheme))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
                        
                        Text("Note: Waypoints does not scrape private social media or fetch external media; pasting text helps find the pin.")
                            .font(WaypointsTypography.caption)
                            .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                    }
                    
                    // 3. Attach Travel Screenshot (Vision OCR)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OR ATTACH TRAVEL SCREENSHOT / IMAGE")
                            .font(WaypointsTypography.eyebrow)
                            .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                        
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                Text(selectedImageData != nil ? "Change Screenshot" : "Pick Screenshot from Photos")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(WaypointsTheme.surface(for: scheme))
                            .foregroundColor(Color.waypointsGreen)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WaypointsTheme.cardBorder(for: scheme), lineWidth: 1))
                        }
                        
                        if isRunningOCR {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(Color.waypointsGreen)
                                Text("Analyzing screenshot pixels with Apple Vision…")
                                    .font(WaypointsTypography.caption)
                                    .foregroundColor(Color.waypointsGreen)
                            }
                            .padding(.top, 4)
                        } else if let ocrNotice {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color.waypointsGreen)
                                Text(ocrNotice)
                                    .font(WaypointsTypography.caption)
                                    .foregroundColor(Color.waypointsGreen)
                                    .fontWeight(.medium)
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    // 4. Collection Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COLLECTION")
                            .font(WaypointsTypography.eyebrow)
                            .foregroundColor(WaypointsTheme.textSecondary(for: scheme))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableCollections, id: \.self) { col in
                                    let isSelected = selectedCollection == col
                                    Button {
                                        selectedCollection = col
                                    } label: {
                                        Text(col)
                                            .font(WaypointsTypography.subheadline)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? Color.waypointsGreen : WaypointsTheme.surface(for: scheme))
                                            .foregroundColor(isSelected ? .white : WaypointsTheme.textPrimary(for: scheme))
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(isSelected ? Color.clear : WaypointsTheme.cardBorder(for: scheme), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Error Notice if Any
                    if let errorMessage {
                        Text(errorMessage)
                            .font(WaypointsTypography.caption)
                            .foregroundColor(Color.red)
                    }
                    
                    // Submit Button
                    PrimaryButton("Save discovery & identify location ➔") {
                        saveAction()
                    }
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .background(WaypointsTheme.background(for: scheme).ignoresSafeArea())
            .navigationTitle("Save a New Discovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(Color.waypointsGreen)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoSelection(newItem)
            }
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isRunningOCR = true
        ocrNotice = nil
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                selectedImageData = data
                let ocrResult = await VisionOCRService.shared.recognizeText(in: data)
                
                await MainActor.run {
                    isRunningOCR = false
                    if ocrResult.isSuccess {
                        if let firstClue = ocrResult.clues.first {
                            if captionText.isEmpty {
                                captionText = firstClue.name
                            } else {
                                captionText += " (\(firstClue.name))"
                            }
                            ocrNotice = "Apple Vision recognized place: \"\(firstClue.name)\""
                        } else if !ocrResult.recognizedText.isEmpty {
                            let preview = String(ocrResult.recognizedText.prefix(60)).replacingOccurrences(of: "\n", with: " ")
                            if captionText.isEmpty {
                                captionText = preview
                            }
                            ocrNotice = "OCR text extracted: \"\(preview)…\""
                        } else {
                            ocrNotice = "No readable location text found in image."
                        }
                    } else {
                        ocrNotice = ocrResult.errorMessage ?? "Could not extract text from image."
                    }
                }
            } else {
                await MainActor.run {
                    isRunningOCR = false
                    ocrNotice = "Could not load image."
                }
            }
        }
    }
    
    private func saveAction() {
        let trimmedUrl = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedUrl.isEmpty && trimmedCaption.isEmpty && selectedImageData == nil {
            errorMessage = "Please provide a link, caption, or travel screenshot."
            return
        }
        
        onSave(trimmedUrl, trimmedCaption, selectedCollection, selectedImageData)
        dismiss()
    }
}
