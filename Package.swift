// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthKitUtility",
    platforms: [
        .iOS(.v18)  // Requires iOS 18.0 for HKCategoryValueVaginalBleeding and latest HealthKit APIs
    ],
    products: [
        // Core library: data models, generators, and HealthKit writer
        // ✅ Safe to use in main app targets
        .library(
            name: "HealthKitTestData",
            type: .dynamic,
            targets: ["HealthKitTestData"]
        ),

        // ⚠️⚠️⚠️ TEST-ONLY LIBRARY - DO NOT IMPORT IN PRODUCTION CODE ⚠️⚠️⚠️
        //
        // This library contains ~2.5MB of JSON fixture files for testing.
        // It MUST ONLY be added to testTarget() declarations, never to regular .target().
        //
        // ❌ WRONG:   .target(name: "MyApp", dependencies: [.product(name: "HealthKitTestHelpers", ...)])
        // ✅ CORRECT: .testTarget(name: "MyAppTests", dependencies: [.product(name: "HealthKitTestHelpers", ...)])
        //
        // Runtime guards will trigger assertionFailure() in release builds if used in production.
        // See Sources/HealthKitTestHelpers/README.md for details.
        .library(
            name: "HealthKitTestHelpers",
            targets: ["HealthKitTestHelpers"]
        )
    ],
    dependencies: [],
    targets: [
        // Core target: models, generators, HealthKit writer
        .target(
            name: "HealthKitTestData",
            dependencies: [],
            path: "Sources/HealthKitTestData"
        ),

        // Test helpers: pre-built fixtures and test utilities
        .target(
            name: "HealthKitTestHelpers",
            dependencies: ["HealthKitTestData"],
            path: "Sources/HealthKitTestHelpers",
            resources: [
                .process("Resources")
            ]
        ),

        // Unit and integration tests
        .testTarget(
            name: "HealthKitTestDataTests",
            dependencies: [
                "HealthKitTestData",
                "HealthKitTestHelpers"
            ],
            path: "Tests/HealthKitTestDataTests"
        )
    ]
)
