
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2023-10-24 - Rasterizing Complex Rotating Views with .drawingGroup()
**Learning:** Complex static views (like compass dials with hundreds of subviews) that are continuously rotated or animated based on frequent updates (like `CLLocationManager` heading) cause significant CPU overhead in CoreAnimation because it attempts to individually manage each subview's layer during every frame.
**Action:** Apply `.drawingGroup()` to such static, complex view hierarchies to rasterize them into a single Metal texture, drastically improving rendering performance and reducing CPU load during frequent transforms.
