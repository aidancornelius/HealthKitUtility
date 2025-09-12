//
//  LiveStreamView.swift
//  HealthKitExporter
//
//  Live data streaming interface for continuous health data generation
//

import SwiftUI

struct LiveStreamView: View {
    @EnvironmentObject var exportManager: ExportManager
    @StateObject private var liveStreamManager = LiveStreamManager()
    @State private var showingFilePicker = false
    @State private var errorMessage: String?
    
    // Data type toggles
    @State private var generateHeartRate = true
    @State private var generateHRV = true
    @State private var generateSteps = true
    @State private var generateCalories = true
    @State private var generateSleep = false
    @State private var generateWorkouts = false
    @State private var generateRespiratory = false
    @State private var generateBloodOxygen = false
    @State private var generateMindfulMinutes = false
    @State private var generateStateOfMind = false
    @State private var generateBodyTemp = false
    @State private var generateMenstrual = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Source Data Section
                Section("Source data") {
                    if let bundle = liveStreamManager.sourceBundle ?? exportManager.lastExportedBundle {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("\(bundle.sampleCount) samples", systemImage: "chart.line.uptrend.xyaxis")
                                Spacer()
                                Text(bundle.exportDate, style: .date)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("HR avg: \(averageHeartRate(from: bundle), specifier: "%.1f") BPM")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("HRV avg: \(averageHRV(from: bundle), specifier: "%.1f") ms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button(action: { showingFilePicker = true }) {
                            Label("Load different data", systemImage: "doc.badge.arrow.up")
                        }
                        .disabled(liveStreamManager.isStreaming)
                        
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No source data loaded")
                                .foregroundStyle(.secondary)
                            Text("Load exported health data to use as baseline for streaming patterns.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button(action: { showingFilePicker = true }) {
                            Label("Load source data", systemImage: "doc.badge.arrow.up")
                        }
                    }
                }
                
                // Data Type Selection Section
                Section("Data types to generate") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Core metrics
                        Text("Core metrics")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ToggleChip(title: "Heart rate", isOn: $generateHeartRate, icon: "heart.fill", color: .red)
                            ToggleChip(title: "HRV", isOn: $generateHRV, icon: "waveform.path.ecg", color: .pink)
                            ToggleChip(title: "Steps", isOn: $generateSteps, icon: "figure.walk", color: .orange)
                            ToggleChip(title: "Calories", isOn: $generateCalories, icon: "flame.fill", color: .orange)
                        }
                        
                        Divider()
                        
                        // Activity metrics
                        Text("Activity & wellness")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ToggleChip(title: "Sleep", isOn: $generateSleep, icon: "bed.double.fill", color: .indigo)
                            ToggleChip(title: "Workouts", isOn: $generateWorkouts, icon: "figure.run", color: .green)
                            ToggleChip(title: "Mindful", isOn: $generateMindfulMinutes, icon: "brain.head.profile", color: .purple)
                            ToggleChip(title: "Mood", isOn: $generateStateOfMind, icon: "face.smiling", color: .blue)
                        }
                        
                        // Enhanced metrics
                        if exportManager.isSimulator || exportManager.overrideModeEnabled {
                            Divider()
                            
                            Text("Enhanced metrics")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ToggleChip(title: "Respiratory", isOn: $generateRespiratory, icon: "wind", color: .cyan)
                                ToggleChip(title: "Blood O₂", isOn: $generateBloodOxygen, icon: "drop.fill", color: .blue)
                                ToggleChip(title: "Body temp", isOn: $generateBodyTemp, icon: "thermometer", color: .yellow)
                                ToggleChip(title: "Menstrual", isOn: $generateMenstrual, icon: "drop.circle", color: .pink)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .disabled(liveStreamManager.isStreaming)
                }
                
                // Streaming Configuration Section
                Section("Streaming configuration") {
                    Picker("Scenario", selection: $liveStreamManager.currentScenario) {
                        ForEach(StreamingScenario.allCases, id: \.self) { scenario in
                            VStack(alignment: .leading) {
                                Text(scenario.rawValue)
                                Text(scenario.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(scenario)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(liveStreamManager.isStreaming)
                    
                    // Show wheelchair toggle when wheelchair scenario is selected
                    if liveStreamManager.currentScenario == .wheelchair {
                        Toggle("Generate wheelchair push data", isOn: $liveStreamManager.generateWheelchairData)
                            .disabled(liveStreamManager.isStreaming)
                        
                        if liveStreamManager.generateWheelchairData {
                            HStack {
                                Image(systemName: "figure.roll")
                                    .foregroundStyle(.purple)
                                Text("Will generate wheelchair pushes and distance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Interval")
                        Spacer()
                        Picker("Interval", selection: $liveStreamManager.streamingInterval) {
                            Text("15 seconds").tag(15.0)
                            Text("30 seconds").tag(30.0)
                            Text("1 minute").tag(60.0)
                            Text("2 minutes").tag(120.0)
                            Text("5 minutes").tag(300.0)
                        }
                        .pickerStyle(.menu)
                    }
                    .disabled(liveStreamManager.isStreaming)
                    
                    // Quick presets
                    HStack {
                        Text("Quick presets:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button("All") {
                            setAllToggles(true)
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        
                        Button("Core only") {
                            setCoreOnly()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        
                        Button("None") {
                            setAllToggles(false)
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                    .disabled(liveStreamManager.isStreaming)
                }
                
                // Live Monitoring Section
                if liveStreamManager.isStreaming || liveStreamManager.totalSamplesGenerated > 0 {
                    Section("Live monitoring") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(liveStreamManager.isStreaming ? .green : .gray)
                                    .frame(width: 8, height: 8)
                                Text(liveStreamManager.streamingStatus)
                                    .font(.subheadline)
                            }
                            
                            if liveStreamManager.isStreaming {
                                HStack {
                                    Text("Samples generated:")
                                    Spacer()
                                    Text("\(liveStreamManager.totalSamplesGenerated)")
                                        .font(.monospaced(.body)())
                                }
                                .font(.caption)
                            }
                        }
                        
                        // Last generated values
                        if !liveStreamManager.lastGeneratedValues.isEmpty {
                            ForEach(Array(liveStreamManager.lastGeneratedValues.keys.sorted()), id: \.self) { key in
                                if let value = liveStreamManager.lastGeneratedValues[key] {
                                    HStack {
                                        Text(key)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(value, specifier: "%.1f")")
                                            .font(.monospaced(.caption)())
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Network Status Section  
                #if !targetEnvironment(simulator)
                Section("Network broadcasting") {
                    HStack {
                        Image(systemName: liveStreamManager.networkStreamingManager.isServerRunning ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                            .foregroundStyle(liveStreamManager.networkStreamingManager.isServerRunning ? .green : .secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Broadcast Status")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(liveStreamManager.networkStreamingManager.isServerRunning ? "Broadcasting to simulators" : "Not broadcasting")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        if liveStreamManager.networkStreamingManager.totalDataSent > 0 {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Sent")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(liveStreamManager.networkStreamingManager.totalDataSent)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    if liveStreamManager.networkStreamingManager.isClientConnected {
                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text("Simulator connected - receiving data")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                #endif
                
                // Streaming Controls Section
                Section("Streaming controls") {
                    if liveStreamManager.isStreaming {
                        Button(action: { liveStreamManager.stopStreaming() }) {
                            Label("Stop streaming", systemImage: "stop.fill")
                                .foregroundStyle(.red)
                        }
                        
                        Button(action: { liveStreamManager.pauseStreaming() }) {
                            Label("Pause streaming", systemImage: "pause.fill")
                                .foregroundStyle(.orange)
                        }
                        
                        Button(action: { liveStreamManager.resumeStreaming() }) {
                            Label("Resume streaming", systemImage: "play.fill")
                                .foregroundStyle(.blue)
                        }
                    } else {
                        Button(action: startStreaming) {
                            Label("Start streaming", systemImage: "play.fill")
                        }
                        .disabled(liveStreamManager.sourceBundle == nil && exportManager.lastExportedBundle == nil)
                    }
                }
                
                // Safety Information Section
                Section("Safety limits") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max samples per hour:")
                            Spacer()
                            Text("3,600")
                                .font(.monospaced(.caption)())
                        }
                        
                        HStack {
                            Text("Max total samples:")
                            Spacer()
                            Text("10,000")
                                .font(.monospaced(.caption)())
                        }
                        
                        Text("Streaming will automatically stop when limits are reached to prevent excessive data generation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Live generation")
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        loadSourceData(url)
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .onAppear {
                // Use last exported bundle if no source data is loaded
                if liveStreamManager.sourceBundle == nil {
                    liveStreamManager.sourceBundle = exportManager.lastExportedBundle
                }
            }
            .onChange(of: liveStreamManager.currentScenario) { newScenario in
                // Automatically enable wheelchair data generation when wheelchair scenario is selected
                if newScenario == .wheelchair {
                    liveStreamManager.generateWheelchairData = true
                }
            }
        }
    }
    
    private func startStreaming() {
        // Ensure we have source data
        if liveStreamManager.sourceBundle == nil {
            liveStreamManager.sourceBundle = exportManager.lastExportedBundle
        }
        
        // Configure what to generate
        liveStreamManager.generateHeartRate = generateHeartRate
        liveStreamManager.generateHRV = generateHRV
        liveStreamManager.generateSteps = generateSteps
        liveStreamManager.generateCalories = generateCalories
        liveStreamManager.generateSleep = generateSleep
        liveStreamManager.generateWorkouts = generateWorkouts
        liveStreamManager.generateRespiratory = generateRespiratory
        liveStreamManager.generateBloodOxygen = generateBloodOxygen
        liveStreamManager.generateMindfulMinutes = generateMindfulMinutes
        liveStreamManager.generateStateOfMind = generateStateOfMind
        liveStreamManager.generateBodyTemp = generateBodyTemp
        liveStreamManager.generateMenstrual = generateMenstrual
        
        liveStreamManager.startStreaming()
        errorMessage = nil
    }
    
    private func setAllToggles(_ value: Bool) {
        generateHeartRate = value
        generateHRV = value
        generateSteps = value
        generateCalories = value
        generateSleep = value
        generateWorkouts = value
        generateRespiratory = value
        generateBloodOxygen = value
        generateMindfulMinutes = value
        generateStateOfMind = value
        generateBodyTemp = value
        generateMenstrual = value
    }
    
    private func setCoreOnly() {
        generateHeartRate = true
        generateHRV = true
        generateSteps = true
        generateCalories = true
        generateSleep = false
        generateWorkouts = false
        generateRespiratory = false
        generateBloodOxygen = false
        generateMindfulMinutes = false
        generateStateOfMind = false
        generateBodyTemp = false
        generateMenstrual = false
    }
    
    private func loadSourceData(_ url: URL) {
        do {
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            liveStreamManager.sourceBundle = try exportManager.loadFromFile(url)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }
    
    private func averageHeartRate(from bundle: ExportedHealthBundle) -> Double {
        guard !bundle.heartRate.isEmpty else { return 0 }
        return bundle.heartRate.map(\.value).reduce(0, +) / Double(bundle.heartRate.count)
    }
    
    private func averageHRV(from bundle: ExportedHealthBundle) -> Double {
        guard !bundle.hrv.isEmpty else { return 0 }
        return bundle.hrv.map(\.value).reduce(0, +) / Double(bundle.hrv.count)
    }
}

// MARK: - Toggle Chip Component

struct ToggleChip: View {
    let title: String
    @Binding var isOn: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(isOn ? .white : color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isOn ? .white : .primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOn ? color : Color(UIColor.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LiveStreamView()
            .environmentObject(ExportManager())
    }
}
