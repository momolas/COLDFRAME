
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-01-20 - Rasterizing Complex Static View Hierarchies
**Learning:** Rendering complex, static view hierarchies with many subviews (like a rotating compass dial with graduations and labels) inside SwiftUI can cause significant CoreAnimation CPU overhead when transformed/rotated frequently based on state changes (e.g. tracking device heading).
**Action:** Use `.drawingGroup()` on such stationary subview combinations to instruct SwiftUI to rasterize them into a single, flat Metal texture before drawing. This reduces the layout calculations per-frame when the parent view rotates or animates.
