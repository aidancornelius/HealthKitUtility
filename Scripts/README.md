# Fixture generation scripts

This directory contains scripts for generating test fixtures for the HealthKit test helpers package.

## GenerateFixtures.swift

A standalone Swift script that generates realistic health data fixture JSON files for testing.

### Usage

Run the script directly from the project root:

```bash
swift Scripts/GenerateFixtures.swift
```

Or make it executable and run:

```bash
chmod +x Scripts/GenerateFixtures.swift
./Scripts/GenerateFixtures.swift
```

### Generated fixtures

The script generates 5 fixture files in `Sources/HealthKitTestHelpers/Resources/Fixtures/`:

1. **high-stress-week.json** - 7 days of high stress data
   - Heart rate: 80-100 BPM (elevated)
   - HRV: 20-40 ms (low, indicating stress)
   - Poor sleep quality (5-6 hours with frequent wake periods)
   - Lower activity levels
   - Fewer workouts (every 3 days)

2. **low-stress-week.json** - 7 days of low stress, optimal health data
   - Heart rate: 55-70 BPM (healthy)
   - HRV: 45-80 ms (high, indicating good health)
   - Good sleep quality (7-8 hours with proper stages)
   - Regular workouts (every 2 days)
   - Moderate activity levels

3. **cycle-tracking.json** - 28-day menstrual cycle with flow tracking
   - Complete 28-day cycle with menstrual flow data
   - Heart rate and HRV variations across cycle phases
   - Body temperature changes (higher in luteal phase)
   - Reduced activity during menstruation
   - Workouts resume after menstruation

4. **edge-cases.json** - 7 days with extreme values for testing edge cases
   - Heart rate: 40-180 BPM (extreme variations)
   - HRV: 10-150 ms (extreme variations)
   - Zero activity periods and extreme activity bursts
   - Very short sleep (insomnia scenario)
   - Marathon workout (4 hours, 42km)
   - Extreme body temperatures (fever and hypothermia risk)

5. **active-lifestyle.json** - 7 days of athletic lifestyle with high activity
   - Heart rate: 50-70 BPM at rest, 130-165 during workouts
   - HRV: 60-95 ms (athletic range)
   - Multiple daily workouts (morning and evening)
   - High step counts (15,000-25,000 daily)
   - Good sleep for recovery (8+ hours)
   - Variety of workout types: Running, Cycling, Swimming, HIIT, Strength Training, Yoga

### Data included

Each fixture includes realistic data for:

- **Heart rate**: Every 5 minutes (high-frequency monitoring)
- **HRV**: Every hour
- **Activity**: Steps, distance, and calories burned (hourly)
- **Sleep**: Daily with stages (light, deep, REM, awake)
- **Workouts**: 2-3 per week with type, duration, calories, distance, average HR
- **Resting heart rate**: Daily values
- **Respiratory rate**: Hourly (in applicable fixtures)
- **Blood oxygen**: Hourly (in applicable fixtures)
- **Body temperature**: Twice daily (in applicable fixtures)
- **Menstrual flow**: Daily during menstruation (cycle-tracking only)
- **Exercise time**: Daily active minutes (active-lifestyle only)

### Reproducibility

The script uses the `SeededRandomGenerator` from the HealthKitTestData package to ensure reproducible results. Each fixture uses a different seed:

- high-stress-week: seed 100
- low-stress-week: seed 200
- cycle-tracking: seed 300
- edge-cases: seed 400
- active-lifestyle: seed 500

Running the script multiple times will produce identical output files.

### Output format

All fixtures are saved as JSON files with:
- ISO8601 date formatting
- Pretty-printed output (readable)
- Sorted keys (consistent ordering)

### Integration

The generated fixtures are automatically loaded by the `HealthKitFixtures` enum in `Sources/HealthKitTestHelpers/Fixtures/HealthKitFixtures.swift`:

```swift
import HealthKitTestHelpers

// Load fixtures in your tests
let normalWeek = HealthKitFixtures.normalWeek
let highStress = HealthKitFixtures.highStressWeek
let lowStress = HealthKitFixtures.lowStressWeek
let cycleTracking = HealthKitFixtures.cycleTracking
let edgeCases = HealthKitFixtures.edgeCases
let activeLifestyle = HealthKitFixtures.activeLifestyle
```
