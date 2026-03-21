
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2023-10-24 - Rasterizing complex static views with .drawingGroup()
**Learning:** Rotating views with a massive number of static subcomponents (like a Compass dial with 180 tick marks and 12 labels) triggers high CPU overhead via CoreAnimation because the UI framework calculates positions individually for each view on every rotation tick.
**Action:** Use the `.drawingGroup()` modifier on complex, frequently-updating static view hierarchies. This forces SwiftUI to flatten and rasterize the views into a single Metal texture, bypassing individual view layouts during rotation and dramatically improving rendering performance.
