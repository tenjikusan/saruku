# Waypoints iOS — Trips & Itineraries Architecture

## 1. Data Model Hierarchy

Waypoints models travel trips using a structured SwiftData relational architecture:

```
+--------------------------------------------------------------+
|                            TRIP                              |
|  - id: String                                                |
|  - name: String (e.g. "Japan 2027")                          |
|  - destination: String (e.g. "Kyoto, Tokyo, Osaka")          |
|  - startDate: Date                                           |
|  - endDate: Date                                             |
|  - tripDescription: String                                   |
|  - colorHex: String                                          |
|  - durationInDays: Int (computed calendar duration)          |
+--------------------------------------------------------------+
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
+-----------------------------+  +-----------------------------+
|        ITINERARY DAY        |  |            PLACE            |
|  - id: String               |  |  (Directly linked places    |
|  - dayNumber: Int (1, 2, 3) |  |   associated with the trip) |
|  - title: String            |  +-----------------------------+
|  - date: Date?              |
|  - notes: String            |
+-----------------------------+
               │
               ▼
+-----------------------------+
|       ITINERARY STOP        |
|  - id: String               |
|  - sortOrder: Int (1, 2, 3) |
|  - placeName: String        |
|  - scheduledTime: String    |
|  - notes: String            |
|  - isCompleted: Bool        |
|  - latitude: Double         |
|  - longitude: Double        |
+-----------------------------+
```

---

## 2. Key Features

1. **Daily Itinerary Planning**:
   - Organizes saved destinations by day (Day 1, Day 2, Day 3...).
   - Each day supports custom titles, specific calendar dates, and daily travel notes.
2. **Ordered Stops**:
   - Stops are ordered sequentially with explicit `sortOrder`.
   - Supports scheduled intended visit times (e.g. "09:30 AM", "02:00 PM").
3. **Consecutive Stop Distance Calculation**:
   - Uses mathematical **Haversine formula** (`CoordinateMath.haversineDistanceKm`) between consecutive stop coordinates.
   - Displays real physical distance (e.g. "3.8 km to next stop").
   - Strictly avoids fabricating AI transit durations or fictional train schedules.
4. **Independent Progress Tracking**:
   - Users can mark individual itinerary stops completed via checkbox.
   - This state is tracked on `ItineraryStop.isCompleted`, preserving the general visited status of the underlying permanent `Place`.
5. **Globe Integration**:
   - Trips can be visualized directly on the 3D Earth Globe using the "Trip Focus" display mode.
