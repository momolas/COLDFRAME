
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-01-15 - Rasterizing complex static views with drawingGroup
**Learning:** Complex static view hierarchies in SwiftUI with many graphical subviews (like the `CompassDial` with its 180+ ticks and text labels) cause significant CoreAnimation CPU overhead when the parent view updates frequently (such as tracking device heading).
**Action:** Always consider appending `.drawingGroup()` to the topmost container of static graphic-heavy elements that rotate or move as a single unit, which offloads the rendering to Metal by rasterizing the layers into a single texture.
