
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-01-22 - Rasterizing Complex Static View Hierarchies in SwiftUI
**Learning:** SwiftUI can struggle to maintain 60/120fps when rapidly animating or rotating very complex, deep view hierarchies built from primitive shapes (like a compass dial with hundreds of `Rectangle` ticks and `Text` labels), because Core Animation attempts to re-render the vector tree each frame.
**Action:** When animating or rotating a complex but entirely static layout (meaning its internal subviews do not change state), apply `.drawingGroup()` to the parent container. This instructs SwiftUI to rasterize the entire sub-tree into a single off-screen Metal texture, turning an expensive vector calculation into a cheap bitmap rotation, dramatically reducing CPU load and preventing dropped frames.
