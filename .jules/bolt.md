
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-10-24 - Rasterizing Rotating Complex Static Views and Using Lazy Stacks
**Learning:** Complex static view hierarchies like a compass dial (containing ~200 graduations/labels) can cause severe CPU overhead during constant rotation updates driven by sensor data. CoreAnimation struggles to redraw all these subviews every sub-second frame. Additionally, horizontal scrolling lists of prayers can unnecessarily render off-screen elements.
**Action:** Use `.drawingGroup()` to rasterize these complex, static rotating views into a single Metal texture, dramatically reducing CPU overhead and improving the rotation frame rate. Furthermore, prefer `LazyHStack` over `HStack` in horizontal ScrollViews for optimal rendering.
