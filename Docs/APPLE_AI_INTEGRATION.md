# Apple Native Intelligence Integration

Waypoints utilizes Apple's native machine learning frameworks on iOS. This architecture guarantees total user privacy, offline functionality, and instant processing speeds without monthly AI API subscriptions.

---

## 1. Apple Vision Framework (On-Device OCR)

### Implementation: `VisionOCRService.swift`
- **Underlying API**: `VNRecognizeTextRequest`
- **Execution Target**: Apple Neural Engine (ANE) / GPU
- **Recognition Level**: `.accurate`
- **Language Detection**: Automatically recognizes English, Japanese, French, Italian, Spanish, German, Chinese, and other Apple-supported languages.

### Use Cases:
1. **Travel Screenshots**: When a user shares or selects a screenshot from Instagram, TikTok, or a travel blog, Vision scans the image and extracts visible destination names, street signs, and geotags.
2. **Photo Intake**: Users can pick a photo directly from their iOS Photo Library (`PhotosPicker`), and Waypoints extracts text clues and coordinates.

---

## 2. Apple NaturalLanguage Framework (NER)

### Implementation: `NaturalLanguageService.swift`
- **Underlying API**: `NLTagger` with tag schemes:
  - `.nameTypeOrLexicalClass`
  - Tag type: `.placeName` and `.organizationName`
- **Execution Target**: On-device NaturalLanguage statistical and transformer models.

### Use Cases:
1. **Caption Parsing**: User captions such as:
   > *"Finally made it to the magical Lake Como in Lombardy after a gorgeous drive through Switzerland!"*
   are parsed into tokens:
   - `Lake Como` -> Place Name (Confidence: High)
   - `Lombardy` -> Place Name (Confidence: High)
   - `Switzerland` -> Place Name (Confidence: High)
2. **Noise Filtering**: Distinguishes generic words ("travel", "vacation", "morning") from bona fide geographical entities.

---

## 3. Foundation Models Service (Apple Intelligence Readiness)

### Implementation: `FoundationModelsService.swift`
- **Runtime Capability Detection**: Queries system availability for Apple Intelligence foundation model capabilities on iOS 18+ and compatible hardware (A17 Pro, M1+).
- **Graceful Fallback**: If Apple Foundation Models are not active on the device, the app falls back seamlessly to `VisionOCRService` and `NaturalLanguageService` without any degradation in core functionality.
- **Zero Third-Party Data Transmission**: Never sends sensitive user photos or personal notes to third-party cloud LLM endpoints unless explicitly configured by the user.
