# Waypoints iOS — Discovery Engine Specification

## 1. Universal Input Handling

The Waypoints Discovery Engine accepts raw user input from any of the following sources:
1. **Direct Map Links**:
   - Google Maps URLs: Marker pin coordinates extracted from `!3d` and `!4d` bang parameters; viewport centers extracted from `@lat,lon`.
   - Apple Maps URLs: Coordinate pairs extracted from `ll=`, `sll=`, and `q=` query parameters.
   - OpenStreetMap URLs: Marker coordinates from `mlat=` / `mlon=`; viewport centers from `#map=zoom/lat/lon`.
2. **Social Media & Video Links**:
   - YouTube: Public video URLs query the YouTube oEmbed endpoint to retrieve real video titles and creator metadata without scraping.
   - Instagram / TikTok / X / Facebook: When direct HTML content is login-gated, the app preserves the URL, issues a clear login-wall notice, and invites the user to paste caption text or attach screenshots.
3. **Screenshots & Photos**:
   - `ImageMetadataExtractor`: Reads camera EXIF GPS tags from photo data (`kCGImagePropertyGPSDictionary`).
   - `VisionOCRService`: Runs Apple Vision `VNRecognizeTextRequest` on device pixels to extract on-screen destination names.
4. **Unstructured Captions**:
   - `NaturalLanguageService`: Runs Apple `NLTagger` with `.place` and `.organization` entity extraction.
   - List & Bullet Parser: Parses numbered items (`"1. Kyoto 2. Nara"`), bulleted lines (`"- Amalfi Coast"`), and colon-separated lists (`"Places to visit: Tokyo, Hakone, Osaka"`).
5. **iOS Share Extension**:
   - Receives items from the system share sheet and places them into the App Group queue.

---

## 2. Pipeline Execution Steps

```
[ Incoming Content: URL, Text, or Photo ]
                   │
                   ▼
[ Step 1: Direct URL Coordinate Extraction ]
  ├── Found marker pin? ───► Exact Pin (.verifiedLink) ───► Needs Confirmation
  └── No URL coords?
                   │
                   ▼
[ Step 2: Text Coordinate Extraction ]
  ├── Found lat/lon string? ─► Exact Pin (.userEntry) ───► Needs Confirmation
  └── No text coords?
                   │
                   ▼
[ Step 3: Photo EXIF GPS Extraction ]
  ├── Found camera GPS? ─────► Exact Pin (.userEntry) ───► Needs Confirmation
  └── No EXIF tags?
                   │
                   ▼
[ Step 4: Clue Extraction (URL slug, hashtags, caption) ]
                   │
                   ▼
[ Step 5: Apple NaturalLanguage NER & List Parsing ]
  ├── Extracts all city/landmark entity tokens
  └── Parses multi-destination bulleted / comma lists
                   │
                   ▼
[ Step 6: Apple Vision OCR (if images attached) ]
  └── OCR extracted text re-fed into NaturalLanguage NER
                   │
                   ▼
[ Step 7: Geocoding Resolution via GeocodingEngine ]
  ├── Searches Photon OpenStreetMap (worldwide index)
  ├── Queries in-memory thread-safe LRU Cache
  └── Fallback: Offline Knowledge Base (50+ destinations)
                   │
                   ▼
[ Step 8: Multi-Candidate Presentation & Confirmation ]
  ├── User reviews candidate list
  ├── User can select single or multiple destinations
  └── User confirms ───► Converted to Place(s) in SwiftData
```

---

## 3. Prevention of Null Island & Data Integrity

- The pipeline **strictly forbids** coercing missing or unparsed coordinates to `0.0, 0.0`.
- If no valid geographic coordinates can be resolved, the discovery is transitioned to `.needsInfo` or `.failed`.
- Every created `Place` record carries an explicit `CoordinateProvenance`:
  - `.verifiedLink`: Exact marker coordinate extracted from map link.
  - `.geocodedResult`: Resolved via Photon OpenStreetMap or LocationIQ.
  - `.globeTap`: Dropped via manual 3D globe tap.
  - `.userEntry`: Entered by user or extracted from camera EXIF GPS tags.
  - `.demoData`: Sourced from offline demonstration database.
