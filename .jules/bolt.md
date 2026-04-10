
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-10-24 - Rasterizing Rotating Complex Static Views and Using Lazy Stacks
**Learning:** Complex static view hierarchies like a compass dial (containing ~200 graduations/labels) can cause severe CPU overhead during constant rotation updates driven by sensor data. CoreAnimation struggles to redraw all these subviews every sub-second frame. Additionally, horizontal scrolling lists of prayers can unnecessarily render off-screen elements.
**Action:** Use `.drawingGroup()` to rasterize these complex, static rotating views into a single Metal texture, dramatically reducing CPU overhead and improving the rotation frame rate. Furthermore, prefer `LazyHStack` over `HStack` in horizontal ScrollViews for optimal rendering.

## 2025-10-24 - Isolating Volatile Properties in @Observable Models
**Learning:** In iOS 17+ with the `@Observable` macro, property access dictates view invalidation. Binding high-frequency updates (like compass headings) directly within a massive parent view causes the entire view (and its siblings) to unnecessarily re-evaluate and re-render multiple times per second, leading to significant CPU overhead.
**Action:** Extract the specific UI components that read highly volatile properties into their own dedicated subviews. This leverages Observation's precise invalidation, ensuring only the isolated subview re-renders on rapid updates, preserving the performance of the rest of the app hierarchy.

## 2025-10-25 - Guarding @Observable Property Mutations
**Learning:** @Observable properties synthesized by Swift 5.9 do not check for equality before calling `withMutation`. Redundant assignments (setting a property to the value it already has) in high-frequency loops like sensor callbacks will indiscriminately invalidate observing views, causing significant CPU overhead.
**Action:** Always guard property mutations with an equality check (e.g. `if property != newValue`) when updating @Observable properties inside high-frequency callbacks to prevent unnecessary view invalidations.
