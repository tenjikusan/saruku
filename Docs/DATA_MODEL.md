# Waypoints iOS — SwiftData Data Models & Schema

This document details the SwiftData schema, entities, relationships, and serialization formats used in Waypoints.

---

## 1. Entity Specifications

### `Place`
- Primary key: `id` (String UUID)
- Attributes:
  - `name`: String
  - `city`: String
  - `region`: String
  - `country`: String
  - `latitude`: Double (strictly validated \([-90, 90]\))
  - `longitude`: Double (strictly validated \([-180, 180]\))
  - `precision`: String (`"exact"` or `"approximate"`)
  - `provenanceRaw`: String (`CoordinateProvenance`)
  - `sourceURL`: Optional String
  - `note`: String
  - `isFavorite`: Bool
  - `isVisited`: Bool
  - `theme`: String
  - `category`: String
  - `source`: String
  - `evidence`: String
  - `discoveryId`: Optional String
  - `imageFileNamesJSON`: Serialized JSON array of relative image file paths
  - `sourceReferencesJSON`: Serialized JSON array of `SourceReference` structs
  - `createdAt`: Date
  - `updatedAt`: Date
- Relationships:
  - `@Relationship(inverse: \CollectionModel.places) var collections: [CollectionModel]`
  - `@Relationship(deleteRule: .cascade) var journalEntries: [JournalEntry]`
  - `@Relationship(inverse: \Trip.places) var trips: [Trip]`

### `Discovery`
- Primary key: `id` (String)
- Attributes:
  - `originalURL`: String
  - `caption`: String
  - `collectionName`: String
  - `statusRaw`: String (`DiscoveryStatus`)
  - `statusMessage`: String
  - `candidatesJSON`: Serialized JSON array of `LocationCandidate`
  - `selectedCandidateJSON`: Serialized JSON `LocationCandidate`
  - `evidenceJSON`: Serialized JSON array of Strings
  - `confirmedPlaceId`: Optional String
  - `imageFilePath`: Optional String (legacy single image)
  - `imageFileNamesJSON`: Serialized JSON array of image file names
  - `createdAt`: Date
  - `updatedAt`: Date

### `CollectionModel`
- Primary key: `id` (String UUID)
- Attributes:
  - `name`: String
  - `collectionDescription`: String
  - `systemIcon`: String (SF Symbol)
  - `colorHex`: String
  - `coverImageFileName`: Optional String
  - `isSmartCollection`: Bool
  - `smartFilterType`: Optional String
  - `sortOrder`: String
  - `createdAt`: Date
  - `updatedAt`: Date
- Relationships:
  - `@Relationship(deleteRule: .nullify) var places: [Place]`

### `Trip`
- Primary key: `id` (String UUID)
- Attributes:
  - `name`: String
  - `destination`: String
  - `startDate`: Date
  - `endDate`: Date
  - `tripDescription`: String
  - `coverImageFileName`: Optional String
  - `colorHex`: String
  - `createdAt`: Date
  - `updatedAt`: Date
- Relationships:
  - `@Relationship(deleteRule: .cascade) var days: [ItineraryDay]`
  - `@Relationship(deleteRule: .nullify) var places: [Place]`

### `ItineraryDay`
- Primary key: `id` (String UUID)
- Attributes:
  - `dayNumber`: Int
  - `title`: String
  - `date`: Optional Date
  - `notes`: String
  - `createdAt`: Date
  - `updatedAt`: Date
- Relationships:
  - `@Relationship(inverse: \Trip.days) var trip: Trip?`
  - `@Relationship(deleteRule: .cascade) var stops: [ItineraryStop]`

### `ItineraryStop`
- Primary key: `id` (String UUID)
- Attributes:
  - `sortOrder`: Int
  - `placeName`: String
  - `notes`: String
  - `scheduledTime`: String
  - `isCompleted`: Bool
  - `latitude`: Double
  - `longitude`: Double
  - `placeId`: Optional String
  - `createdAt`: Date
  - `updatedAt`: Date
- Relationships:
  - `@Relationship(inverse: \ItineraryDay.stops) var day: ItineraryDay?`

### `JournalEntry`
- Primary key: `id` (String UUID)
- Attributes:
  - `title`: String
  - `note`: String
  - `visitDate`: Date
  - `rating`: Int (1 to 5)
  - `imageFileNamesJSON`: Serialized JSON array of image file names
  - `tripId`: Optional String
  - `placeId`: Optional String
  - `placeName`: String
  - `createdAt`: Date
  - `updatedAt`: Date
- Relationships:
  - `@Relationship(inverse: \Place.journalEntries) var place: Place?`

---

## 2. Supporting Value Types

- `CoordinateProvenance`: Enum (`.verifiedLink`, `.geocodedResult`, `.globeTap`, `.userEntry`, `.demoData`)
- `LocationCandidate`: Struct representing geocoded candidate record
- `SourceReference`: Struct representing external post/article links attached to a `Place`
- `SharedItem`: Struct representing items queued by the Share Extension
- `WidgetDataSnapshot`: Lightweight Codable snapshot read by widgets
