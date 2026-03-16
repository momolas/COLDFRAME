## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-01-22 - Rasterizing Complex SwiftUI Stacks during Rotation
**Learning:** Rotating complex `ZStack`s with many subviews (like a compass dial with 180 graduations and labels) triggers expensive CoreAnimation recalculations and layout passes on every frame if bound to high-frequency state like device heading.
**Action:** Use `.drawingGroup()` on complex, mostly static view hierarchies that are frequently transformed. This rasterizes the hierarchy into a single Metal texture, significantly reducing CPU overhead and dropping frame rates.
