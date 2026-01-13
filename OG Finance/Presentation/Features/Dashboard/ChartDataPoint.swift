//
//  ChartDataPoint.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Represents a single data point for charts.
struct ChartDataPoint: Identifiable, Equatable, Sendable {
    let id = UUID()
    let label: String
    let value: Double
    let isCurrentPeriod: Bool
}
