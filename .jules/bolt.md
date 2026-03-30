
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.
## 2025-03-30 - drawingGroup() for complex SwiftUI static elements
**Learning:** Drawing complex views with hundreds of static graphical subviews (like the 180 traits of the `CompassDial` inside a `ZStack`) repeatedly on the main thread is computationally heavy for CoreAnimation. SwiftUI has to compute each element individually every frame during rotations or animations.
**Action:** When working with large sets of simple, static views that update together inside an animation or rotation (e.g. dials, compasses), use `.drawingGroup()` to rasterize them into a single Metal texture. This significantly drops CPU overhead and increases frame rate predictability.
