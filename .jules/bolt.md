
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-01-01 - Rasterizing Complex Rotational Views
**Learning:** High-frequency rotation of complex view hierarchies (like a compass dial with hundreds of `Rectangle` and `Text` subviews) driven by CoreLocation updates creates a severe CoreAnimation CPU bottleneck. SwiftUI redraws and recalculates transform matrices for every subview independently.
**Action:** Use `.drawingGroup()` on static, complex subviews that are frequently transformed as a whole. This instructs SwiftUI to composite the view into a single off-screen Metal texture before rendering, collapsing hundreds of transform calculations into a single texture rotation and vastly improving rendering performance.
