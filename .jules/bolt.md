
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-12-17 - Rasterizing Complex Static Views with .drawingGroup()
**Learning:** In SwiftUI, animating or rotating a view hierarchy that contains a large number of static subviews (like the `CompassDial` with 180 tick marks and 12 text labels) can cause significant CoreAnimation CPU overhead, as it tries to calculate layout and rendering for every individual subview on every frame.
**Action:** When a complex static view hierarchy is frequently rotated or scaled (such as a compass dial driven by `CLLocationManager` heading updates), always apply the `.drawingGroup()` modifier to rasterize the entire hierarchy into a single Metal texture. This offloads the rendering work to the GPU and drastically improves frame rates and battery usage.
