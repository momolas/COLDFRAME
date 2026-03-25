## 2024-03-24 - [Optimize CompassDial Render Performance]
**Learning:** Frequent rotation of a SwiftUI view containing hundreds of static subviews (like the `CompassDial` with 180 rectangle ticks and 12 labels) causes significant CoreAnimation CPU overhead. Every 1° heading update triggers a layout recalculation and CPU-based compositing of all 192 layers.
**Action:** Use `.drawingGroup()` on complex, mostly-static view hierarchies that undergo frequent transformations (like rotation). This rasterizes the hierarchy into a single Metal texture, offloading compositing to the GPU and drastically reducing CPU usage, leading to smoother animations and lower battery consumption during continuous compass use.

## 2024-03-24 - [Avoid Overwriting Bolt Journal]
**Learning:** Overwriting the `.jules/bolt.md` file deletes previous performance insights, which defeats the purpose of maintaining a journal of critical learnings.
**Action:** Always append to the `.jules/bolt.md` file instead of overwriting it to preserve historical context.
