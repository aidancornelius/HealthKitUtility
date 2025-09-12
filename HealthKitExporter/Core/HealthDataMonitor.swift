//
//  HealthDataMonitor.swift
//  HealthKitExporter
//
//  Real-time monitoring of HealthKit data changes
//

import Foundation
import HealthKit
import Combine

// MARK: - Log Entry Model

struct HealthDataLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let changeType: ChangeType
    let category: DataCategory
    let value: String
    let source: String
    let metadata: [String: Any]?
    
    enum ChangeType: String {
        case new = "NEW"
        case update = "UPDATE"
        case delete = "DELETE"
        case query = "QUERY"
        case initial = "INITIAL"
    }
    
    enum DataCategory: String {
        case heartRate = "Heart rate"
        case hrv = "HRV"
        case steps = "Steps"
        case distance = "Distance"
        case calories = "Calories"
        case sleep = "Sleep"
        case workout = "Workout"
        case respiratoryRate = "Respiratory"
        case bloodOxygen = "Blood oxygen"
        case skinTemperature = "Skin temp"
        case wheelchairPushes = "Wheelchair"
        case exerciseTime = "Exercise"
        case bodyTemperature = "Body temp"
        case menstrualFlow = "Menstrual"
        case mindfulMinutes = "Mindful"
        case stateOfMind = "Mood"
        case unknown = "Unknown"
    }
    
    static func == (lhs: HealthDataLogEntry, rhs: HealthDataLogEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Health Data Monitor

@MainActor
class HealthDataMonitor: ObservableObject {
    private let healthStore = HKHealthStore()
    private var queries: [HKQuery] = []
    private var observers: [HKObserverQuery] = []
    
    @Published var logEntries: [HealthDataLogEntry] = []
    @Published var isMonitoring = false
    @Published var lastUpdateTime = Date()
    
    private let maxLogEntries = 500
    
    // MARK: - Start Monitoring
    
    func startMonitoring() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw ExportError.healthKitUnavailable
        }
        
        // Request authorization first
        try await requestAuthorization()
        
        isMonitoring = true
        
        // Add initial entry
        addLogEntry(
            changeType: .initial,
            category: .unknown,
            value: "Monitoring started",
            source: "System"
        )
        
        // Setup observers for different data types
        setupHeartRateObserver()
        setupHRVObserver()
        setupActivityObserver()
        setupSleepObserver()
        setupWorkoutObserver()
        
        if #available(iOS 16.0, *) {
            setupEnhancedMetricsObservers()
        }
        
        setupMindfulnessObserver()
        
        if #available(iOS 18.0, *) {
            setupStateOfMindObserver()
        }
        
        // Start initial queries to get recent data
        await performInitialQueries()
    }
    
    // MARK: - Stop Monitoring
    
    func stopMonitoring() {
        isMonitoring = false
        
        // Stop all queries
        for query in queries {
            healthStore.stop(query)
        }
        queries.removeAll()
        
        for observer in observers {
            healthStore.stop(observer)
        }
        observers.removeAll()
        
        addLogEntry(
            changeType: .initial,
            category: .unknown,
            value: "Monitoring stopped",
            source: "System"
        )
    }
    
    // MARK: - Authorization
    
    private func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .pushCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWheelchair)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Setup Observers
    
    private func setupHeartRateObserver() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let observer = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            if error == nil {
                Task { @MainActor in
                    self?.queryHeartRateData()
                }
            }
            completionHandler()
        }
        
        observers.append(observer)
        healthStore.execute(observer)
    }
    
    private func setupHRVObserver() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let observer = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] query, completionHandler, error in
            if error == nil {
                Task { @MainActor in
                    self?.queryHRVData()
                }
            }
            completionHandler()
        }
        
        observers.append(observer)
        healthStore.execute(observer)
    }
    
    private func setupActivityObserver() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let observer = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] query, completionHandler, error in
            if error == nil {
                Task { @MainActor in
                    self?.queryActivityData()
                }
            }
            completionHandler()
        }
        
        observers.append(observer)
        healthStore.execute(observer)
    }
    
    private func setupSleepObserver() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let observer = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] query, completionHandler, error in
            if error == nil {
                Task { @MainActor in
                    self?.querySleepData()
                }
            }
            completionHandler()
        }
        
        observers.append(observer)
        healthStore.execute(observer)
    }
    
    private func setupWorkoutObserver() {
        let workoutType = HKWorkoutType.workoutType()
        
        let observer = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] query, completionHandler, error in
            if error == nil {
                Task { @MainActor in
                    self?.queryWorkoutData()
                }
            }
            completionHandler()
        }
        
        observers.append(observer)
        healthStore.execute(observer)
    }
    
    private func setupEnhancedMetricsObservers() {
        if #available(iOS 16.0, *) {
            // Respiratory rate
            if let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) {
                let observer = HKObserverQuery(sampleType: respiratoryType, predicate: nil) { [weak self] query, completionHandler, error in
                    if error == nil {
                        Task { @MainActor in
                            self?.queryRespiratoryData()
                        }
                    }
                    completionHandler()
                }
                observers.append(observer)
                healthStore.execute(observer)
            }
            
            // Blood oxygen
            if let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) {
                let observer = HKObserverQuery(sampleType: oxygenType, predicate: nil) { [weak self] query, completionHandler, error in
                    if error == nil {
                        Task { @MainActor in
                            self?.queryBloodOxygenData()
                        }
                    }
                    completionHandler()
                }
                observers.append(observer)
                healthStore.execute(observer)
            }
        }
    }
    
    private func setupMindfulnessObserver() {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let observer = HKObserverQuery(sampleType: mindfulType, predicate: nil) { [weak self] query, completionHandler, error in
            if error == nil {
                Task { @MainActor in
                    self?.queryMindfulnessData()
                }
            }
            completionHandler()
        }
        
        observers.append(observer)
        healthStore.execute(observer)
    }
    
    private func setupStateOfMindObserver() {
        if #available(iOS 18.0, *) {
            let stateOfMindType = HKSampleType.stateOfMindType()
            
            let observer = HKObserverQuery(sampleType: stateOfMindType, predicate: nil) { [weak self] query, completionHandler, error in
                if error == nil {
                    Task { @MainActor in
                        self?.queryStateOfMindData()
                    }
                }
                completionHandler()
            }
            
            observers.append(observer)
            healthStore.execute(observer)
        }
    }
    
    // MARK: - Query Methods
    
    private func queryHeartRateData() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else { return }
            
            Task { @MainActor in
                for sample in samples {
                    let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    self?.addLogEntry(
                        changeType: .new,
                        category: .heartRate,
                        value: String(format: "%.0f bpm", bpm),
                        source: sample.sourceRevision.source.name,
                        metadata: sample.metadata
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func queryHRVData() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else { return }
            
            Task { @MainActor in
                for sample in samples {
                    let ms = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    self?.addLogEntry(
                        changeType: .new,
                        category: .hrv,
                        value: String(format: "%.1f ms", ms),
                        source: sample.sourceRevision.source.name,
                        metadata: sample.metadata
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func queryActivityData() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: stepType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else { return }
            
            Task { @MainActor in
                for sample in samples {
                    let steps = sample.quantity.doubleValue(for: HKUnit.count())
                    self?.addLogEntry(
                        changeType: .new,
                        category: .steps,
                        value: String(format: "%.0f steps", steps),
                        source: sample.sourceRevision.source.name,
                        metadata: sample.metadata
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func querySleepData() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else { return }
            
            Task { @MainActor in
                for sample in samples {
                    let sleepValue = self?.sleepValueString(for: sample.value) ?? "Unknown"
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
                    self?.addLogEntry(
                        changeType: .new,
                        category: .sleep,
                        value: "\(sleepValue) - \(String(format: "%.1f hrs", duration))",
                        source: sample.sourceRevision.source.name,
                        metadata: sample.metadata
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func queryWorkoutData() {
        let workoutType = HKWorkoutType.workoutType()
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let samples = samples as? [HKWorkout], error == nil else { return }
            
            Task { @MainActor in
                for workout in samples {
                    let duration = workout.duration / 60
                    let activityName = self?.workoutActivityName(for: workout.workoutActivityType) ?? "Unknown"
                    self?.addLogEntry(
                        changeType: .new,
                        category: .workout,
                        value: "\(activityName) - \(String(format: "%.0f min", duration))",
                        source: workout.sourceRevision.source.name,
                        metadata: workout.metadata
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func queryRespiratoryData() {
        guard let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: respiratoryType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else { return }
            
            Task { @MainActor in
                for sample in samples {
                    let rate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    self?.addLogEntry(
                        changeType: .new,
                        category: .respiratoryRate,
                        value: String(format: "%.1f breaths/min", rate),
                        source: sample.sourceRevision.source.name,
                        metadata: sample.metadata
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func queryBloodOxygenData() {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: oxygenType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else { return }
            
            Task { @MainActor in
                for sample in samples {
                    let percentage = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
                    self?.addLogEntry(
                        changeType: .new,
                        category: .bloodOxygen,
                        value: String(format: "%.0f%%", percentage),
                        source: sample.sourceRevision.source.name,
                        metadata: sample.metadata
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func queryMindfulnessData() {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: mindfulType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else { return }
            
            Task { @MainActor in
                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60
                    self?.addLogEntry(
                        changeType: .new,
                        category: .mindfulMinutes,
                        value: String(format: "%.1f minutes", duration),
                        source: sample.sourceRevision.source.name,
                        metadata: sample.metadata
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func queryStateOfMindData() {
        if #available(iOS 18.0, *) {
            let stateOfMindType = HKSampleType.stateOfMindType()
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: stateOfMindType, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
                guard let samples = samples as? [HKStateOfMind], error == nil else { return }
                
                Task { @MainActor in
                    for stateOfMind in samples {
                        // Get valence and primary label
                        let valence = stateOfMind.valence
                        let valenceText = valence > 0 ? "Pleasant" : valence < 0 ? "Unpleasant" : "Neutral"
                        
                        // Get the primary label if available
                        var labelText = ""
                        if !stateOfMind.labels.isEmpty {
                            let label = stateOfMind.labels[0]
                            labelText = self?.labelToString(label) ?? "Unknown"
                        }
                        
                        let moodDescription = labelText.isEmpty ? valenceText : "\(labelText) (\(valenceText))"
                        
                        self?.addLogEntry(
                            changeType: .new,
                            category: .stateOfMind,
                            value: moodDescription,
                            source: stateOfMind.sourceRevision.source.name,
                            metadata: nil
                        )
                    }
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    @available(iOS 18.0, *)
    private func labelToString(_ label: HKStateOfMind.Label) -> String {
        switch label {
        case .amazed: return "Amazed"
        case .amused: return "Amused"
        case .angry: return "Angry"
        case .anxious: return "Anxious"
        case .ashamed: return "Ashamed"
        case .brave: return "Brave"
        case .calm: return "Calm"
        case .confident: return "Confident"
        case .content: return "Content"
        case .disappointed: return "Disappointed"
        case .discouraged: return "Discouraged"
        case .disgusted: return "Disgusted"
        case .embarrassed: return "Embarrassed"
        case .excited: return "Excited"
        case .frustrated: return "Frustrated"
        case .grateful: return "Grateful"
        case .guilty: return "Guilty"
        case .happy: return "Happy"
        case .hopeless: return "Hopeless"
        case .indifferent: return "Indifferent"
        case .irritated: return "Irritated"
        case .jealous: return "Jealous"
        case .joyful: return "Joyful"
        case .lonely: return "Lonely"
        case .passionate: return "Passionate"
        case .peaceful: return "Peaceful"
        case .proud: return "Proud"
        case .relieved: return "Relieved"
        case .sad: return "Sad"
        case .scared: return "Scared"
        case .stressed: return "Stressed"
        case .surprised: return "Surprised"
        case .worried: return "Worried"
        @unknown default: return "Unknown"
        }
    }
    
    // MARK: - Initial Queries
    
    private func performInitialQueries() async {
        // Query recent data for all types
        queryHeartRateData()
        queryHRVData()
        queryActivityData()
        querySleepData()
        queryWorkoutData()
        
        if #available(iOS 16.0, *) {
            queryRespiratoryData()
            queryBloodOxygenData()
        }
        
        queryMindfulnessData()
        
        if #available(iOS 18.0, *) {
            queryStateOfMindData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func addLogEntry(changeType: HealthDataLogEntry.ChangeType, category: HealthDataLogEntry.DataCategory, value: String, source: String, metadata: [String: Any]? = nil) {
        let entry = HealthDataLogEntry(
            timestamp: Date(),
            changeType: changeType,
            category: category,
            value: value,
            source: source,
            metadata: metadata
        )
        
        logEntries.insert(entry, at: 0)
        lastUpdateTime = Date()
        
        // Keep only recent entries
        if logEntries.count > maxLogEntries {
            logEntries = Array(logEntries.prefix(maxLogEntries))
        }
    }
    
    private func sleepValueString(for value: Int) -> String {
        if #available(iOS 16.0, *) {
            switch value {
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                return "Asleep"
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                return "Core sleep"
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                return "Deep sleep"
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                return "REM sleep"
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                return "Awake"
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                return "In bed"
            default:
                return "Unknown"
            }
        } else {
            switch value {
            case HKCategoryValueSleepAnalysis.asleep.rawValue:
                return "Asleep"
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                return "Awake"
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                return "In bed"
            default:
                return "Unknown"
            }
        }
    }
    
    private func workoutActivityName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength"
        case .traditionalStrengthTraining: return "Weights"
        case .coreTraining: return "Core"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stairs"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .cooldown: return "Cooldown"
        case .wheelchairWalkPace: return "Wheelchair walk"
        case .wheelchairRunPace: return "Wheelchair run"
        default: return "Other"
        }
    }
    
    // MARK: - Clear Log
    
    func clearLog() {
        logEntries.removeAll()
        addLogEntry(
            changeType: .initial,
            category: .unknown,
            value: "Log cleared",
            source: "System"
        )
    }
}