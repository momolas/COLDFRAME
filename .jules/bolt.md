## 2024-05-24 - Throttle CoreLocation Updates to prevent excessive re-renders
**Learning:** `CLLocationManager` updates can occur very frequently, causing excessive `Observable` view re-renders in SwiftUI. Since Qibla accuracy doesn't require millimeter precision or micro-degree heading changes, unthrottled updates waste battery and CPU cycles.
**Action:** Always apply `distanceFilter` and `headingFilter` to `CLLocationManager` instances to throttle updates, particularly when observing changes in `@MainActor @Observable` view models.
