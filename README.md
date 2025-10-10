# HealthKit Utility

A Swift package for generating and importing realistic HealthKit test data in the iOS Simulator.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS 18.0+](https://img.shields.io/badge/iOS-18.0+-blue.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)

## Why this exists

When building health apps, the iOS Simulator can't generate real health data because it doesn't have sensors. This package solves that problem by letting you:

- Generate synthetic health data with somewhat realistic patterns (heart rate, HRV, sleep, activity, etc.)
- Import data into HealthKit in the simulator for testing
- Use pre-built fixtures for consistent test data across your project/team/whatever
- Stream live data continuously to test 'real-time' app behaviour

For unit tests, UI tests, and prototyping health features.

## Quick start

### 1. Add the package

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/aidancornelius/HealthKitUtility", from: "1.0.0")
]

// Your target
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "HealthKitTestData", package: "HealthKitUtility")
    ]
)
```

### 2. Configure Info.plist

Add this to your `Info.plist`:
```xml
<key>NSHealthUpdateUsageDescription</key>
<string>Write test data to HealthKit for app testing</string>
```

Enable the HealthKit capability in your Xcode project.

### 3. Generate and import data

```swift
import HealthKit
import HealthKitTestData

// Request authorization
let healthStore = HKHealthStore()
let types: Set<HKSampleType> = [
    HKObjectType.quantityType(forIdentifier: .heartRate)!,
    HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
]
try await healthStore.requestAuthorization(toShare: types, read: [])

// Generate 7 days of realistic data
let bundle = SyntheticDataGenerator.generateHealthData(
    preset: .normal,              // or .lowerStress, .higherStress, .edgeCases
    manipulation: .smoothReplace,
    startDate: Date().addingTimeInterval(-7 * 86400),
    endDate: Date(),
    seed: 42                      // For reproducible data
)

// Import into HealthKit (simulator only)
let writer = HealthKitWriter(healthStore: healthStore)
try await writer.importData(bundle)

// Your app now has realistic test data!
```

## Features

### Generate synthetic data

```swift
// Different stress profiles
let normalData = SyntheticDataGenerator.generateHealthData(
    preset: .normal,
    startDate: weekAgo,
    endDate: now
)

let stressedData = SyntheticDataGenerator.generateHealthData(
    preset: .higherStress,  // Higher HR, lower HRV
    startDate: weekAgo,
    endDate: now
)

let edgeCases = SyntheticDataGenerator.generateHealthData(
    preset: .edgeCases,     // Extreme values for testing
    startDate: weekAgo,
    endDate: now
)
```

### Use fixtures

**Note**: `HealthKitTestHelpers` is for **test targets only**. Don't import it in production code - it bundles JSON fixture files that increase app size.

```swift
// In your test target Package.swift:
.testTarget(
    name: "YourAppTests",
    dependencies: [
        .product(name: "HealthKitTestHelpers", package: "HealthKitUtility")
    ]
)

// In your test code:
import HealthKitTestHelpers

// Available fixtures:
let normal = HealthKitFixtures.normalWeek          // 7 days, normal health (HR 60-80, HRV 30-70)
let highStress = HealthKitFixtures.highStressWeek  // 7 days, elevated stress (HR 80-100, HRV 20-40)
let lowStress = HealthKitFixtures.lowStressWeek    // 7 days, optimal health (HR 55-70, HRV 45-80)
let cycle = HealthKitFixtures.cycleTracking        // 28 days with menstrual flow tracking
let edges = HealthKitFixtures.edgeCases            // 7 days with extreme values
let active = HealthKitFixtures.activeLifestyle     // 7 days, athletic with multiple daily workouts

// Use any fixture
try await writer.importData(HealthKitFixtures.normalWeek)
```

### Stream data continuously

```swift
// Generate data every 60 seconds
let config = LiveGenerationConfig(
    preset: .normal,
    samplingInterval: 60
)

let loop = LiveDataLoop(config: config, writer: writer)
try await loop.start()

// ... data streams continuously ...

loop.stop()
```

### Transpose dates

```swift
// Shift historical data to current dates
let oldData = try loadFromFile("last-week.json")
let currentData = DateTransformation.transposeBundleDatesToToday(oldData)
try await writer.importData(currentData)
```

## Supported data types

- Heart rate & resting heart rate
- Heart rate variability (HRV)
- Activity (steps, distance, calories)
- Sleep analysis (light, deep, REM)
- Workouts
- Respiratory rate
- Blood oxygen
- Body temperature
- Wheelchair activity
- Menstrual flow
- And more

## Testing with the package

```swift
import XCTest
@testable import YourApp
import HealthKitTestData

class HealthFeatureTests: XCTestCase {
    func testHeartRateProcessing() async throws {
        // Use mock store for testing
        let mockStore = MockHealthStore()
        let writer = HealthKitWriter(healthStore: mockStore)

        // Generate test data
        let bundle = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            seed: 42  // Reproducible!
        )

        try await writer.importData(bundle)

        // Test your app's logic
        let processor = HeartRateProcessor()
        let result = try await processor.analyze(bundle.heartRate)

        XCTAssertEqual(result.average, 70, accuracy: 5)
    }
}
```

## Documentation

- [Integration guide](INTEGRATION.md) - Setup, entitlements, and advanced usage
- [Contributing](CONTRIBUTING.md) - Contributing and migrating code from the main app

## Requirements

- iOS 18.0+
- Swift 6.0+
- Xcode 16.0+
- iOS Simulator (for importing data - HealthKit write restrictions should prevent imports on physical devices)

## What's in the box

### HealthKitTestData (core library)

- `SyntheticDataGenerator` - Generate realistic health data
- `HealthKitWriter` - Import data into HealthKit (simulator only)
- `LiveDataLoop` - Continuously generate and stream data
- `DateTransformation` - Transpose historical data to current dates
- All health data models (`HeartRateSample`, `HRVSample`, etc.)

### HealthKitTestHelpers (test utilities) ⚠️ TEST-ONLY

Test targets only, contains JSON fixtures that shouldn't ship in production.

- `HealthKitFixtures` - Pre-built test data bundles:
  - `normalWeek` - 7 days of typical health data
  - `highStressWeek` - 7 days with elevated stress markers
  - `lowStressWeek` - 7 days of optimal health
  - `cycleTracking` - 28-day menstrual cycle with flow tracking
  - `edgeCases` - 7 days with extreme values for edge case testing
  - `activeLifestyle` - 7 days of athletic lifestyle with multiple workouts

## Example: UI test

```swift
import XCTest
import HealthKitTestHelpers

class HeartRateChartUITests: XCTestCase {
    func testChartDisplaysData() async throws {
        let app = XCUIApplication()

        // Populate simulator HealthKit
        let bundle = HealthKitFixtures.normalWeek
        try await writer.importData(bundle)

        app.launch()

        // Verify chart renders with data
        XCTAssertTrue(app.images["HeartRateChart"].exists)
    }
}
```

## License

MIT License - See [LICENSE](LICENSE) for details.

## Acknowledgments

Built by [Aidan Cornelius-Bell](https://github.com/aidancornelius) to make health app testing less painful.

## Development

This repository contains the Swift package and the HealthKit Utility companion app.

### Package development

Work directly in `Sources/` and `Tests/`:

```bash
# Run tests
swift test

# Or use Xcode
open Package.swift
```

### App development

The app (now) uses XcodeGen to generate the Xcode project from `project.yml`.

**First time:**

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   ./generate_project.sh
   ```

3. Open the generated project:
   ```bash
   open HealthKitExporter.xcodeproj
   ```

**After pulling changes:**

If `project.yml` has been updated, regenerate the project:
```bash
./generate_project.sh
```

**When making changes:**

- Don't edit `.xcodeproj` directly (it's gitignored and regenerated)
- Edit `project.yml` for project configuration changes
- Edit source files normally in Xcode

## Related

This package is extracted from the HealthKit Utility app (included in this repo), which provides a full GUI for exporting real device data, network streaming, and live generation with background tasks.
