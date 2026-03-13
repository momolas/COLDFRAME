## 2026-03-13 - Throttle CLLocationManager updates
**Learning:** `CLLocationManager` without `distanceFilter` and `headingFilter` fires updates constantly, flooding the main thread with `@MainActor` delegate callbacks and causing excessive SwiftUI re-renders.
**Action:** Always set `distanceFilter` and `headingFilter` when initializing `CLLocationManager` to throttle updates and conserve battery.
