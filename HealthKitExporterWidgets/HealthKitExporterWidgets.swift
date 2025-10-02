//
//  HealthKitExporterWidgets.swift
//  HealthKitExporterWidgets
//
//  Widget bundle for HealthKit Exporter Live Activities
//

import SwiftUI
import WidgetKit

/// Widget bundle containing all Live Activity widgets for HealthKit Exporter.
///
/// Includes:
/// - ``LiveStreamActivityWidget``: Real-time health data generation display
/// - ``NetworkStreamActivityWidget``: Network streaming status display
@main
struct HealthKitExporterWidgets: WidgetBundle {
    var body: some Widget {
        LiveStreamActivityWidget()
        NetworkStreamActivityWidget()
    }
}