# Waypoints iOS — Apple Native Intelligence Architecture

Waypoints uses Apple's native machine learning and computer vision frameworks directly on iPhone hardware.

---

## 1. Apple Vision Framework (`VisionOCRService.swift`)

- **API**: `VNRecognizeTextRequest`
- **Execution Target**: Apple Neural Engine (ANE) / GPU
- **Recognition Level**: `.accurate` with automatic language detection.
- **Workflow**:
  1. User selects screenshot or photo via `PhotosPicker`.
  2. Image bytes are saved to durable local storage (`LocalMediaStorage`).
  3. `VNRecognizeTextRequest` parses all text elements into normalized strings.
  4. Extracted text is fed into `NaturalLanguageService` to isolate destination names.

---

## 2. Apple NaturalLanguage Framework (`NaturalLanguageService.swift`)

- **API**: `NLTagger` with `.nameType` and `.lexicalClass` schemes.
- **Entity Detection**:
  - Filters `.place` (cities, regions, landmarks) and `.organization` (monasteries, parks, museums).
  - Minimum word length and capitalization heuristics filter common noise words.
- **Multi-Location List Parser**:
  - Sentence Lists: Recognizes colon-separated destination sequences (e.g. `"Top 5 places: Kyoto, Nara, Osaka"`).
  - Bulleted Lists: Extracts line-by-line items with dashes, asterisks, or numbered markers.

---

## 3. Photograph EXIF GPS Extraction (`ImageMetadataExtractor.swift`)

- **API**: `ImageIO` framework (`CGImageSourceCopyPropertiesAtIndex`).
- **Target**: `kCGImagePropertyGPSDictionary` reading `kCGImagePropertyGPSLatitude`, `kCGImagePropertyGPSLongitude`, and orientation refs.
- **Privacy & Transparency**:
  - Extracted coordinates are explicitly labeled with source `"Photo EXIF Metadata"` and attribution `"Photograph Metadata"`.
  - Strictly distinguishes camera hardware GPS from textual entity recognition.

---

## 4. Intelligent Category Classification (`IntelligentCategorizer.swift`)

- Contextual lexical analysis categorizing places into 10 primary categories:
  - Temples & Shrines
  - Beaches & Coasts
  - Mountains & Hiking
  - Food & Dining
  - Historic Sites
  - Museums & Art
  - Nature & Parks
  - Scenic Viewpoints
  - City & Urban
  - Hotels & Stays

---

## 5. Foundation Models Integration (`FoundationModelsService.swift`)

- **Status**: **Unimplemented optional integration**.
- **Design**: Configured to coexist with iOS 17.0 base deployment target via runtime `#available(iOS 18.0, *)` availability gates.
- **Current Behavior**: Always returns unavailable (`false`) and delegates to `NaturalLanguageService` for entity recognition.
