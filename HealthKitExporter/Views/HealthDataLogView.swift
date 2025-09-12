//
//  HealthDataLogView.swift
//  HealthKitExporter
//
//  Live health data monitoring view - airport status board style
//

import SwiftUI

struct HealthDataLogView: View {
    @StateObject private var monitor = HealthDataMonitor()
    @State private var autoScroll = true
    @State private var filterCategory: HealthDataLogEntry.DataCategory?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status bar
                statusBar
                
                // Filter bar
                filterBar
                
                // Log entries
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredEntries) { entry in
                                LogEntryRow(entry: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .background(Color(UIColor.systemBackground))
                    .onChange(of: monitor.logEntries.count) { oldCount, newCount in
                        if autoScroll && newCount > oldCount, let first = monitor.logEntries.first {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(first.id, anchor: .top)
                            }
                        }
                    }
                }
                
                // Control bar
                controlBar
            }
            .navigationTitle("Health data monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { monitor.clearLog() }) {
                            Label("Clear log", systemImage: "trash")
                        }
                        
                        Toggle("Auto-scroll", isOn: $autoScroll)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            if !monitor.isMonitoring {
                try? await monitor.startMonitoring()
            }
        }
        .onDisappear {
            if monitor.isMonitoring {
                monitor.stopMonitoring()
            }
        }
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(monitor.isMonitoring ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(monitor.isMonitoring ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: monitor.isMonitoring ? 8 : 0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: monitor.isMonitoring)
                    )
                
                Text(monitor.isMonitoring ? "MONITORING" : "STOPPED")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(monitor.isMonitoring ? Color.green : Color.red)
            }
            
            Spacer()
            
            Text("\(monitor.logEntries.count) entries")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(monitor.lastUpdateTime, style: .time)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: filterCategory == nil,
                    action: { filterCategory = nil }
                )
                
                ForEach(allCategories, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: filterCategory == category,
                        action: { filterCategory = category }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Control Bar
    
    private var controlBar: some View {
        HStack {
            Button(action: toggleMonitoring) {
                HStack {
                    Image(systemName: monitor.isMonitoring ? "pause.fill" : "play.fill")
                    Text(monitor.isMonitoring ? "Pause" : "Resume")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(monitor.isMonitoring ? Color.orange : Color.green)
                .clipShape(Capsule())
            }
            
            Spacer()
            
            Toggle("Auto-scroll", isOn: $autoScroll)
                .font(.system(size: 12))
                .toggleStyle(.switch)
                .labelsHidden()
                .overlay(
                    Text("AUTO")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .offset(x: -40)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Helpers
    
    private var filteredEntries: [HealthDataLogEntry] {
        if let category = filterCategory {
            return monitor.logEntries.filter { $0.category == category }
        }
        return monitor.logEntries
    }
    
    private var allCategories: [HealthDataLogEntry.DataCategory] {
        let categories = Set(monitor.logEntries.map { $0.category })
        return Array(categories).sorted { $0.rawValue < $1.rawValue }
    }
    
    private func toggleMonitoring() {
        if monitor.isMonitoring {
            monitor.stopMonitoring()
        } else {
            Task {
                try? await monitor.startMonitoring()
            }
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: HealthDataLogEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Timestamp
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.timestamp, style: .time)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Text(relativeTime)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // Change type indicator
            Text(entry.changeType.rawValue)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(changeTypeColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: 65)
            
            // Category
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category.rawValue.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(categoryColor)
                Text(entry.source)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 100, alignment: .leading)
            
            // Value
            Text(entry.value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var changeTypeColor: Color {
        switch entry.changeType {
        case .new:
            return .green
        case .update:
            return .blue
        case .delete:
            return .red
        case .query:
            return .purple
        case .initial:
            return .gray
        }
    }
    
    private var categoryColor: Color {
        switch entry.category {
        case .heartRate:
            return .red
        case .hrv:
            return .pink
        case .steps, .distance, .calories:
            return .orange
        case .sleep:
            return .indigo
        case .workout:
            return .green
        case .respiratoryRate:
            return .cyan
        case .bloodOxygen:
            return .blue
        case .skinTemperature, .bodyTemperature:
            return .yellow
        case .wheelchairPushes, .exerciseTime:
            return .purple
        case .menstrualFlow:
            return .pink
        case .mindfulMinutes:
            return .purple
        case .stateOfMind:
            return .blue
        case .unknown:
            return .gray
        }
    }
    
    private var relativeTime: String {
        let interval = Date().timeIntervalSince(entry.timestamp)
        if interval < 1 {
            return "now"
        } else if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(UIColor.tertiarySystemFill))
                )
        }
    }
}

// MARK: - Preview

#Preview {
    HealthDataLogView()
}