# Integration guide

How to integrate HealthKit Utility into your iOS app or test suite.

## Setup checklist

- [ ] Add package dependency
- [ ] Enable HealthKit capability
- [ ] Add Info.plist usage strings
- [ ] Request HealthKit authorization
- [ ] Generate and import test data

## 1. Add package dependency

### Swift Package Manager (recommended)

**In Xcode:**
1. File → Add Package Dependencies
2. Enter: `https://github.com/aidancornelius/HealthKitUtility`
3. Select version: `1.0.0` or later
4. Add `HealthKitTestData` to your main target
5. Add `HealthKitTestHelpers` to your test targets

**In Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/aidancornelius/HealthKitUtility", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "HealthKitTestData", package: "HealthKitUtility")
        ]
    ),
    .testTarget(
        name: "YourAppTests",
        dependencies: [
            "YourApp",
            .product(name: "HealthKitTestHelpers", package: "HealthKitUtility")
        ]
    )
]
```

## 2. Enable HealthKit capability

### In Xcode:
1. Select your project in the navigator
2. Select your target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "HealthKit"

### Entitlements file:
Your `YourApp.entitlements` should include:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
</dict>
</plist>
```

**Note:** Only include the `health-records` entitlement if you need Clinical Records API access (requires? Apple approval).

## 3. Add Info.plist usage strings

Explain why your app needs HealthKit access:

```xml
<key>NSHealthUpdateUsageDescription</key>
<string>Write synthetic test data to HealthKit for app testing and development</string>

<key>NSHealthShareUsageDescription</key>
<string>Read health data to generate test samples (optional - only if you're exporting real data)</string>
```

## 4. Request authorisation

Before importing data, request write permissions for the data types you need:

```swift
import HealthKit
import HealthKitTestData

func requestHealthKitAuthorization() async throws {
    guard HKHealthStore.isHealthDataAvailable() else {
        throw HealthKitError.healthKitUnavailable
    }

    let healthStore = HKHealthStore()

    let typesToWrite: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]

    try await healthStore.requestAuthorization(toShare: typesToWrite, read: [])
}
```

## 5. Generate and import data

### Usage

```swift
import HealthKitTestData

// 1. Create writer with authorized store
let healthStore = HKHealthStore()
let writer = HealthKitWriter(healthStore: healthStore)

// 2. Generate data
let bundle = SyntheticDataGenerator.generateHealthData(
    preset: .normal,
    manipulation: .smoothReplace,
    startDate: Date().addingTimeInterval(-7 * 86400), // 7 days ago
    endDate: Date(),
    seed: 42 // Reproducible
)

// 3. Import to HealthKit
try await writer.importData(bundle)
```

### Using fixtures

```swift
import HealthKitTestHelpers

// Available pre-built fixtures:
let normal = HealthKitFixtures.normalWeek          // 7 days, normal health
let highStress = HealthKitFixtures.highStressWeek  // 7 days, elevated stress
let lowStress = HealthKitFixtures.lowStressWeek    // 7 days, optimal health
let cycle = HealthKitFixtures.cycleTracking        // 28 days with menstrual cycle
let edges = HealthKitFixtures.edgeCases            // 7 days, extreme values
let active = HealthKitFixtures.activeLifestyle     // 7 days, athletic lifestyle

// Use any fixture
try await writer.importData(HealthKitFixtures.normalWeek)
```

### Continuous generation

```swift
let config = LiveGenerationConfig(
    preset: .normal,
    samplingInterval: 60 // seconds
)

let loop = LiveDataLoop(config: config, writer: writer)
try await loop.start()

// Later...
loop.stop()
```

## Platform requirements

### Minimum versions
- **iOS:** 18.0+
- **Swift:** 6.0+
- **Xcode:** 16.0+

### Simulator vs Device

| Feature | Simulator | Physical Device |
|---------|-----------|----------------|
| Import data | Yes | No (HealthKit restrictions) |
| Generate data | Yes | Yes |
| Export to JSON | Yes | Yes (if you add export code) |

Note: HealthKit should prevent third-party apps from writing arbitrary data on physical devices. This package is for iOS Simulator testing only.

## Workflows

### Unit testing

```swift
import XCTest
@testable import YourApp
import HealthKitTestData

class HeartRateTests: XCTestCase {
    func testHeartRateAnalysis() async throws {
        // Use mock store
        let mock = MockHealthStore()
        let writer = HealthKitWriter(healthStore: mock)

        // Generate reproducible data
        let bundle = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            seed: 123
        )

        try await writer.importData(bundle)

        // Test your logic
        let analyzer = HeartRateAnalyzer()
        let result = try await analyzer.analyze(bundle.heartRate)

        XCTAssertEqual(result.average, 70, accuracy: 10)
    }
}
```

### UI testing

```swift
import XCTest
import HealthKitTestHelpers

class HealthChartUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testChartRendersWithData() async throws {
        // Populate HealthKit before launching app
        let healthStore = HKHealthStore()
        let writer = HealthKitWriter(healthStore: healthStore)

        let bundle = HealthKitFixtures.normalWeek
        try await writer.importData(bundle)

        // Launch app
        let app = XCUIApplication()
        app.launch()

        // Verify UI
        XCTAssertTrue(app.staticTexts["Heart Rate"].exists)
        XCTAssertTrue(app.images["ChartView"].exists)
    }
}
```

### Development/debugging

```swift
// In your app's debug menu or development scene
Button("Populate Test Data") {
    Task {
        let bundle = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            startDate: Date().addingTimeInterval(-30 * 86400),
            endDate: Date()
        )

        try await writer.importData(bundle)
        print("Imported \(bundle.sampleCount) samples")
    }
}
```

## Advanced

### Custom patterns

```swift
// Generate data, then modify it
var bundle = SyntheticDataGenerator.generateHealthData(
    preset: .normal,
    startDate: weekAgo,
    endDate: now
)

// Apply stress pattern to heart rate
bundle.heartRate = PatternGenerator.apply(
    pattern: .amplified,
    to: bundle.heartRate,
    seed: 42
)

// Apply relaxation pattern to HRV
bundle.hrv = PatternGenerator.apply(
    pattern: .reduced, // Higher HRV = less stress
    to: bundle.hrv,
    seed: 42
)

try await writer.importData(bundle)
```

### Shift historical data to today

```swift
let oldBundle = try loadFromJSON("backup-2023-01-15.json")
let currentBundle = DateTransformation.transposeBundleDatesToToday(oldBundle)
try await writer.importData(currentBundle)
```

### Dependency injection

```swift
// Production code
protocol HealthDataProvider {
    func fetchHeartRate(from: Date, to: Date) async throws -> [HeartRateSample]
}

// Test implementation
class MockHealthDataProvider: HealthDataProvider {
    func fetchHeartRate(from: Date, to: Date) async throws -> [HeartRateSample] {
        let bundle = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            startDate: from,
            endDate: to,
            seed: 42
        )
        return bundle.heartRate
    }
}
```

## Troubleshooting

### "HealthKit is not available"
- Use `#if targetEnvironment(simulator)` to guard simulator-only code

### "Authorisation denied"
- Check Info.plist usage strings are added
- Check HealthKit capability is enabled
- Reset simulator: Device → Erase All Content and Settings

### "No such module 'HealthKitTestData'"
- Verify package dependency is added
- Check product name is correct
- Clean build: Cmd+Shift+K

### Fixture not found
- Check fixture is in `Resources/Fixtures/`
- Check it's marked as a resource in Package.swift

### Tests failing on CI
- Use GitHub Actions `macos-latest` with iOS Simulator destination

## Need help?

- Issues: https://github.com/aidancornelius/HealthKitUtility/issues
- Discussions: https://github.com/aidancornelius/HealthKitUtility/discussions
- Contributing: See [CONTRIBUTING.md](CONTRIBUTING.md)
