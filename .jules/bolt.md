
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2023-10-24 - Rasterizing Static Complexity with drawingGroup()
**Learning:** Complex static view hierarchies, like a compass dial with hundreds of small graduation lines and text labels, create massive CoreAnimation CPU overhead when the parent view is continuously rotated by high-frequency `CLLocationManager` updates. The layout system struggles to re-calculate these tiny vectors every frame.
**Action:** Always append `.drawingGroup()` to large, static SwiftUI `ZStack`s or `Canvas` equivalents that are subject to frequent transformations. This rasterizes the hierarchy into a single Metal texture, offloading the rotation to the GPU and ensuring smooth 60fps frame rates.
