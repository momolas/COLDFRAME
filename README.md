# COLDFRAME

COLDFRAME is a modern, premium iOS application designed to help Muslims observe their daily and monthly religious practices. Built with SwiftUI and Swift 6.2, it combines elegant design with precise astronomical calculations.

## Core Features

- **Qibla Compass**: A high-precision digital compass pointing to the Kaaba (Mecca) with an elegant Neumorphic dial.
- **Haptic Feedback**: Subtle haptic confirmation when the device is perfectly aligned with the Qibla.
- **Accurate Prayer Times**: Fully offline, localized prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha) calculated based on your coordinates using SwiftAA.
- **Moon Phase Tracking**: Real-time Islamic date and lunar phase tracking, displaying the precise age of the moon and its current form.
- **Hilal Observation Tracker**: Intelligently predicts the visibility of the new crescent moon (Hilal) at Maghrib time, indicating whether it will be visible, difficult to see, or impossible on key observation days.
- **Modern & Premium UI**: A sleek, dark-themed interface featuring subtle gradients, gold typography, and glassmorphism elements, adhering to the latest Apple UI standards.
- **Privacy First**: All location data and astronomical calculations are processed entirely on-device. No data is sent to external servers.

## Requirements

- iOS 26.0+
- Swift 6.2+
- Xcode with Swift 6.2 support

## Installation

1. Open `COLDFRAME.xcodeproj` in Xcode.
2. Wait for package dependencies (e.g. SwiftAA) to resolve.
3. Build and run on your physical iOS device (the compass and location features require a physical device).
4. Grant Location and Notification access when prompted.

## Architecture & Development

The app strictly follows modern Swift concurrency paradigms and the newest declarative SwiftUI techniques:
- Powered by `@Observable` models annotated with `@MainActor`.
- Relies on structured concurrency (`async`/`await`).
- Leverages the modern `FormatStyle` API for all date formatting instead of legacy formatters.

See `AGENTS.md` for a comprehensive detail on coding guidelines and architectural standards applied in this project.
