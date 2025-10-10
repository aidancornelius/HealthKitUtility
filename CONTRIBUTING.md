# Contributing

This guide covers external contributions and migrating code from the main HealthKit Utility app.

## For external contributors

### Reporting issues

- Search existing issues first
- Include iOS, Xcode, and Swift versions
- Provide a minimal reproducible example
- Describe expected vs actual behaviour

### Pull requests

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if needed
5. Run tests
6. Update docs if needed
7. Commit and push
8. Open a pull request

### Code style

- Follow Swift API design guidelines
- Use clear variable and function names
- Document public APIs
- Add `@available` annotations for iOS version requirements


### What stays in the app

Keep these features in the HealthKit Utility app (they're not suitable for the package):

- **UI components** - SwiftUI views, view models with `@Published`
- **Live Activities** - `ActivityKit` widgets for lock screen
- **Background generation** - `BGTaskScheduler`, `AVAudioSession` for continuous generation
- **Network streaming** - Bonjour service discovery, network communication
- **Export features** - Exporting from real devices (requires device-specific HealthKit reads)
- **App lifecycle** - App delegate, scene delegate
- **Settings and preferences** - `UserDefaults`, settings screens

### What goes in the package

In the package:

- **Data models** - `ExportedHealthBundle`, sample types
- **Generators** - `SyntheticDataGenerator`, `PatternGenerator`
- **Writers** - `HealthKitWriter` (simulator import only)
- **Utilities** - Date transformation, seeded random
- **Test helpers** - Fixtures, mock stores
- **Core logic** - Platform-independent health data manipulation

### Example migration

**Before (in app):**
```swift
// HealthKitExporter/Core/ExportManager.swift
import SwiftUI

@MainActor
class ExportManager: ObservableObject {
    @Published var selectedPreset: GenerationPreset = .normal

    func generateData() -> ExportedHealthBundle {
        return SyntheticDataGenerator.generateHealthData(
            preset: selectedPreset,
            ...
        )
    }
}
```

**After (package):**
```swift
// Sources/HealthKitTestData/Generators/SyntheticDataGenerator.swift
import Foundation

@available(iOS 16.0, *)
public struct SyntheticDataGenerator {
    public static func generateHealthData(
        preset: GenerationPreset,
        ...
    ) -> ExportedHealthBundle {
        // Implementation
    }
}
```

**App updated to use package:**
```swift
// HealthKitExporter/Core/ExportManager.swift
import SwiftUI
import HealthKitTestData  // Package import

@MainActor
class ExportManager: ObservableObject {
    @Published var selectedPreset: GenerationPreset = .normal

    func generateData() -> ExportedHealthBundle {
        return SyntheticDataGenerator.generateHealthData(  // Now from package
            preset: selectedPreset,
            ...
        )
    }
}
```

### Adding new data types

When adding support for a new HealthKit data type:

1. **Add model** in `Sources/HealthKitTestData/Models/HealthDataModels.swift`
   ```swift
   @available(iOS 16.0, *)
   public struct NewTypeSample: Codable, Sendable {
       public let date: Date
       public let value: Double
       public let source: String

       public init(date: Date, value: Double, source: String) {
           self.date = date
           self.value = value
           self.source = source
       }
   }
   ```

2. **Add to bundle** in `ExportedHealthBundle`
   ```swift
   public let newType: [NewTypeSample]?
   ```

3. **Add generator** in `Sources/HealthKitTestData/Generators/SyntheticDataGenerator.swift`
   ```swift
   private static func generateNewTypeData(...) -> [NewTypeSample] {
       // Implementation
   }
   ```

4. **Add writer** in `Sources/HealthKitTestData/Writers/HealthKitWriter.swift`
   ```swift
   private func convertNewTypeSamples(_ samples: [NewTypeSample]) throws -> [HKQuantitySample] {
       // Conversion to HealthKit
   }
   ```

5. **Add test** in `Tests/HealthKitTestDataTests/Unit/`
   ```swift
   func testGeneratesNewType() throws {
       let bundle = SyntheticDataGenerator.generateHealthData(...)
       XCTAssertFalse(bundle.newType?.isEmpty ?? true)
   }
   ```

6. **Update documentation** in README.md and INTEGRATION.md

### Running tests locally

```bash
# Run all tests
swift test

# Run specific test
swift test --filter GeneratorTests

# With verbose output
swift test --verbose
```