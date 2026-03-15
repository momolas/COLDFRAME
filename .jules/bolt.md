
## 2023-10-24 - Throttling CLLocationManager with @Observable
**Learning:** High-frequency `CLLocationManager` delegate updates (heading and location) can cause massive performance issues when bound directly to SwiftUI `@Observable` models, as every sub-degree or sub-meter change triggers main thread re-renders. The `distanceFilter` and `headingFilter` are essential to throttle these updates without sacrificing perceived user precision.
**Action:** Always verify if `distanceFilter` and `headingFilter` are set when initializing `CLLocationManager` instances that power reactive UI properties, keeping the frequency of updates meaningful and conservative.

## 2025-03-15 - Rasterizing complex static views with .drawingGroup()
**Learning:** In SwiftUI, rendering a large number of static vector views (like a compass dial with 180+ ticks and text labels) inside a rapidly updating container (like a view rotating via `rotationEffect` based on heading updates) causes massive CPU spikes and frame drops, because CoreAnimation attempts to update every individual layer.
**Action:** Use the `.drawingGroup()` modifier on the static parent view (e.g., the `ZStack` containing the dial ticks). This instructs SwiftUI to rasterize the complex hierarchy into a single flat Metal texture before it is rotated, drastically improving rendering performance and reducing CPU usage during animations.

## 2025-03-15 - Optimizing horizontal scrolling lists with LazyHStack
**Learning:** Standard `HStack` instantiates all of its child views immediately, which can cause performance bottlenecks when iterating over collections, even small ones.
**Action:** Always prefer `LazyHStack` (or `LazyVStack`) when creating lists of items (e.g., `PrayerTimesList`). Additionally, when using `.enumerated()` inside a `ForEach`, wrap the sequence in `Array()` and use `id: \.offset` to correctly satisfy SwiftUI's `RandomAccessCollection` requirement.

## 2025-03-15 - Swift KeyPath tuple limitation in ForEach
**Learning:** You cannot use `id: \.offset` when wrapping an enumerated sequence in an Array (e.g., `Array(collection.enumerated())`) for SwiftUI `ForEach`. This is because `.enumerated()` returns an array of tuples, and Swift KeyPaths do not support tuple elements, leading to compilation errors.
**Action:** When a collection's elements already conform to `Identifiable` (like `PrayerTime`), simply use `ForEach(collection)`. If an index is truly needed, use `ForEach(collection.indices, id: \.self)`. Avoid `enumerated()` in SwiftUI `ForEach` constructs unless strictly wrapping a custom `Identifiable` wrapper struct.
