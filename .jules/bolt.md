
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2023-10-25 - Rasterizing complex static views with .drawingGroup()
**Learning:** In SwiftUI, `ZStack`s containing a large number of overlapping simple views (e.g., tick marks and text labels for a compass dial) cause significant CoreAnimation CPU overhead when animated or rotated frequently. Since the dial's content doesn't change relative to itself, rendering it as individual layers is highly inefficient.
**Action:** Apply `.drawingGroup()` to complex, static view hierarchies that undergo transformations (like rotation) as a whole. This rasterizes the hierarchy into a single Metal texture, offloading the work to the GPU and vastly improving animation frame rates.
