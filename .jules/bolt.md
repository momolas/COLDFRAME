
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2026-03-31 - Rasterizing Complex Static Dials with .drawingGroup()
**Learning:** A static SwiftUI view with numerous distinct subviews (like a compass dial containing 180 graduation marks and 12 text labels) can incur significant CPU overhead when continuously rotated during frequent updates. CoreAnimation attempts to update the layout for each distinct element, degrading frame rates and battery life.
**Action:** Always apply `.drawingGroup()` to complex, static view hierarchies that undergo continuous transformations (e.g., rotation). This forces SwiftUI to rasterize the hierarchy into a single Metal texture, bypassing individual CoreAnimation layout calculations for its subviews during the rotation.
