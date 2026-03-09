
## 2025-03-09 - [iOS CoreLocation & SwiftUI Optimization]
**Learning:** In location-based SwiftUI apps, unthrottled `CLLocationManager` updates combined with eager rendering (`HStack` in `ScrollView`) can cause massive unnecessary re-renders when heading changes rapidly. Applying `distanceFilter` and `headingFilter` natively on the manager prevents the event spam from hitting the React-like view update cycle entirely.
**Action:** Next time working with continuous hardware sensors (GPS/Compass/Motion), apply throttling/filtering as close to the hardware layer/manager level as possible before the state updates hit the main thread and trigger UI redraws.
