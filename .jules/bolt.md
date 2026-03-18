
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2026-03-18 - Rasterizing Complex Static Rotating Views
**Learning:** A static view hierarchy containing hundreds of subviews (like tick marks and labels in a compass dial) causes high Core Animation CPU overhead when it rotates rapidly due to bound data changes (e.g., compass heading updates), as SwiftUI attempts to manage each element's transformation independently.
**Action:** Use `.drawingGroup()` on complex, frequently updating static view hierarchies to rasterize them into a single Metal texture, significantly reducing Core Animation CPU overhead and improving frame rates.
