# HealthKitTestHelpers

⚠️ **TEST-ONLY MODULE - DO NOT IMPORT IN PRODUCTION CODE**

## Purpose

This module contains pre-built JSON fixture files for testing. It is designed **exclusively for test targets** and should never be imported in your main application code.

## ❌ WRONG - Will ship 2.5MB of test data in production

```swift
// Package.swift
.target(
    name: "MyApp",  // ← Main app target
    dependencies: [
        .product(name: "HealthKitTestHelpers", package: "HealthKitUtility")  // ❌ DON'T DO THIS
    ]
)
```

## ✅ CORRECT - Only in test targets

```swift
// Package.swift
.testTarget(
    name: "MyAppTests",  // ← Test target only
    dependencies: [
        "MyApp",
        .product(name: "HealthKitTestHelpers", package: "HealthKitUtility")  // ✅ Correct
    ]
)
```

## What's included

- **JSON Fixtures** (~2.5MB total):
  - `normal-week.json` (26KB)
  - `high-stress-week.json` (334KB)
  - `low-stress-week.json` (335KB)
  - `cycle-tracking.json` (1.2MB)
  - `edge-cases.json` (207KB)
  - `active-lifestyle.json` (335KB)

- **HealthKitFixtures** - Static properties to load fixtures

## Runtime protection

This module includes runtime guards that will trigger `assertionFailure()` in release builds if accidentally imported in production code.

## For production code

Use `HealthKitTestData` instead, which provides generators without bundled fixtures:

```swift
import HealthKitTestData

// Generate data programmatically (no fixtures bundled)
let bundle = SyntheticDataGenerator.generateHealthData(
    preset: .normal,
    startDate: weekAgo,
    endDate: now
)
```

## Questions?

See the main [README.md](../../README.md) for full documentation.
