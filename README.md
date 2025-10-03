# HealthKit Utility

A companion app for developers building health apps that need realistic test data in the iOS Simulator.

## Why this exists

When you're building a health app, the iOS Simulator can't generate real health data because it doesn't have sensors. You might be testing heart rate visualisations, sleep analysis, or activity tracking, but without real data, you're testing in a vacuum. This makes it hard to catch edge cases, validate UI layouts with actual values, or demonstrate your app to stakeholders.

This tool bridges that gap. It lets you capture actual health data from your iPhone and Apple Watch, then import it into the Simulator's HealthKit store. You can also generate synthetic data with specific patterns (like stress scenarios or edge cases) to test how your app handles different physiological states.

## What it does

The app adapts based on where it's running:

On physical devices, export your real HealthKit data to JSON files. Stream health data live over your local network to a simulator.

In the Simulator, import those JSON files into HealthKit. Generate synthetic data continuously with different physiological patterns. Receive live health data from a physical device over your network.

On both, generate synthetic test data with controllable patterns and edge cases. Monitor HealthKit changes in real-time to verify your app is writing data correctly.

## Features

### Export (physical devices)

Captures your actual HealthKit data and saves it to a JSON file. You choose a date range and which metrics to include. Supports heart rate, HRV, steps, distance, calories, sleep stages, workouts, respiratory rate, blood oxygen, skin temperature, wheelchair activity, mindfulness sessions, menstrual data, and mood logs.

Useful when you want to test your app with the kind of messy, real-world data that actual humans generate.

### Import (simulator)

Takes those exported JSON files and writes them into the Simulator's HealthKit database. Includes automatic date transposition, so if you exported data from last week, it can shift everything forward so it ends today. This is helpful when testing features that care about recency.

### Generate

Creates synthetic health data with controllable characteristics. You can:

- Apply patterns to real data (stable, trending, spiky) to test different scenarios
- Generate completely new datasets with stress presets (normal, stressed, extreme events, edge cases)
- Convert step data to wheelchair pushes for accessibility testing
- Set a random seed for reproducible test data

Useful for automated testing where you need consistent, predictable data.

### Live generate (simulator)

Continuously generates health data in real-time, simulating what a real device does. Choose scenarios like normal activity, workouts, sleep, or stress, and it generates samples at regular intervals in the background (even when the app is backgrounded, using silent audio playback and background tasks). Includes Live Activities to show streaming status on your lock screen.

Helpful when testing apps that respond to ongoing health data, like meditation apps tracking heart rate during a session.

### Network stream

Enables real-time streaming between a physical device and the Simulator over your local network:

- On the device broadcasts live HealthKit data as it's generated
- In the Simulator discovers nearby devices and receives that data, automatically writing it to HealthKit

This is particularly useful when you want to test your app's behaviour with real sensor data without constantly exporting and importing files. The Simulator receives actual heart rate readings from your Apple Watch as they happen.

### Monitor

Shows a live log of all HealthKit changes, so you can verify that your app is writing data correctly. Displays what type of data changed, the values, and the source. Useful for debugging when you're not sure if your HealthKit writes are actually working.

## Supported data types

Heart rate, heart rate variability, steps, walking/running distance, active calories, sleep analysis (including core/deep/REM if available), workouts, respiratory rate, blood oxygen, skin temperature, wheelchair pushes and distance, exercise minutes, body temperature, menstrual flow, mindfulness sessions, and state of mind (iOS 18+).

Some metrics are read-only in HealthKit (resting heart rate, skin temperature) so they can't be imported, but everything else works.

## Requirements

- iOS 18.5 or later (can probably lower this, untested)
- Xcode 16 or later
- HealthKit entitlements configured
- For network streaming: devices on the same local network

## Setup

1. Open `HealthKitExporter.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on a physical device or simulator

The app will request HealthKit permissions when it first launches. Grant read access for any data types you want to export, and write access (on simulator) for any you want to import.

## How to use it

**Basic workflow for testing with real data:**

1. Run the app on your physical iPhone
2. Go to the Export tab, select a date range and data types
3. Export to a JSON file and save it (AirDrop to your Mac, save to Files, etc.)
4. Run your app-in-development in the Simulator
5. Open HealthKit Utility in the Simulator
6. Go to the Import tab, load that JSON file
7. Import it into HealthKit (with date transposition enabled if you want recent data)
8. Your app now has realistic test data to work with

**For testing with live streaming:**

1. Make sure your iPhone and Mac are on the same local network
2. Run HealthKit Utility on your iPhone, go to Network stream tab
3. Start the server (grant local network permission if prompted)
4. In the Simulator, run HealthKit Utility and go to Network stream
5. Start discovery, select your iPhone from the list
6. Connect, and you'll start receiving live health data
7. Your app in the Simulator can now read real-time data as it streams in

**For synthetic data generation:**

1. Open the Generate tab
2. Choose whether to transform existing data or generate new synthetic data
3. Select a stress preset (normal, high stress, extreme events, edge cases)
4. Set your target date range
5. Generate and export the JSON file
6. Import into the Simulator as above

## Notes

- The app hides incompatible features (you can't import on a physical device because HealthKit won't let apps write to real users' health data outside of specific contexts)
- There's a developer override mode in Settings that shows all features everywhere, useful if you need to test the full interface on one device, or, you know to break things
- Live generation uses aggressive background processing techniques (silent audio, background tasks, Live Activities) to keep running when backgrounded
- Network streaming automatically handles service discovery via Bonjour and includes verification that data was actually saved to HealthKit

## Use cases

- Testing how your app handles real physiological patterns (heart rate variability during stress, sleep stage transitions)
- Automated UI testing with reproducible synthetic data
- Demonstrating your app to stakeholders with realistic data
- Testing edge cases (very high heart rate, irregular HRV, sparse data with gaps)
- Accessibility testing with wheelchair activity data
- Debugging HealthKit writes by monitoring what actually gets saved

## Project structure

- `HealthKitExporter/Core/`: Core managers (ExportManager, HealthDataExporter, LiveStreamManager, NetworkStreamingManager, HealthDataMonitor)
- `HealthKitExporter/Views/`: SwiftUI views for each tab
- `HealthKitExporter/Models/`: Data models matching HealthKit types
- `HealthKitExporterWidgets/`: Live Activity widgets for streaming status

## License

This is a development tool, built for developers. Use it however it's helpful. Available under MIT. Would love to be pinged if it helps you! 
