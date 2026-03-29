
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2026-03-29 - Rasterizing Static View Hierarchies
**Learning:** Complex static view hierarchies (like compass dials with hundreds of subviews) that are frequently rotated or animated cause significant CoreAnimation CPU overhead when rendered individually at 60fps.
**Action:** Use `.drawingGroup()` on these static containers to rasterize them into a single Metal texture, offloading the rendering work to the GPU and vastly improving frame rates.
