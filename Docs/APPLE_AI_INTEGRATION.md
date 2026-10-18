# Apple Native Intelligence Integration

Waypoints utilizes Apple's native machine learning frameworks on iOS. This architecture keeps processing on-device for user privacy and offline functionality.

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
1. **Caption Parsing**: User captions are parsed into tokens to identify place and organization names.
2. **Noise Filtering**: Distinguishes generic words ("travel", "vacation", "morning") from bona fide geographical entities.

---

## 3. Foundation Models Integration (Unimplemented Optional Integration)

### Implementation: `FoundationModelsService.swift`
- **Current Status**: **Unimplemented placeholder / stub**.
- **Coexistence with Deployment Target**: The iOS 17.0 base deployment target can coexist with iOS 18+ system foundation model APIs via `#available(iOS 18.0, *)` and optional framework linking.
- **Current Behavior**: `isAvailableOnCurrentDevice` returns `false`, and `understandComplexDescription` transparently falls back to `NaturalLanguageService`.
- **Privacy Boundary**: No remote LLM services or paid third-party AI APIs are invoked.
