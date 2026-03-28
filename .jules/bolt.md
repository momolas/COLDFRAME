
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-01-20 - Drawing Group for SwiftUI Compass Dials
**Learning:** Complex static SwiftUI hierarchies (like a compass dial with hundreds of tick marks and text views) incur heavy CPU overhead via CoreAnimation when rotated continuously (e.g., from `CLLocationManager` heading updates). They redraw individual layers on every frame.
**Action:** Use `.drawingGroup()` on the container view to rasterize its static subviews into a single Metal texture. This offloads the rendering work to the GPU and massively reduces CPU usage during rotation.
