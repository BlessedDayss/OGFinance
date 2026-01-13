//
//  Statistics.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Computed statistics for a given time period.
///
/// This is an **immutable** value type because:
/// - Statistics are always derived from transactions
/// - They represent a snapshot at computation time
/// - No direct editing of statistics is ever needed
///
/// - Note: Domain entities are pure Swift types with no persistence dependencies.
struct Statistics: Equatable, Sendable {
    
    // MARK: - Properties
    
    /// Time period these statistics cover
    let period: DateInterval
    
    /// Total income for the period
    let totalIncome: Decimal
    
    /// Total expenses for the period
    let totalExpenses: Decimal
    
    /// Number of transactions in the period
    let transactionCount: Int
    
    /// Breakdown by category
    let categoryBreakdown: [CategoryStatistic]
    
    /// Daily spending/income averages
    let dailyAverages: DailyAverages
    
    // MARK: - Computed Properties
    
    /// Net balance change for the period
    var netChange: Decimal {
        totalIncome - totalExpenses
    }
    
    /// Savings rate as percentage (0-100)
    /// - Returns: nil if no income in the period
    var savingsRate: Double? {
        guard totalIncome > 0 else { return nil }
        let rate = (totalIncome - totalExpenses) / totalIncome
        return Double(truncating: rate as NSNumber) * 100
    }
    
    /// Whether the period had positive net change
    var isPositive: Bool {
        netChange >= 0
    }
}

// MARK: - Category Statistic

/// Statistics for a single category within a period
struct CategoryStatistic: Identifiable, Equatable, Sendable {
    let id: UUID // Category ID
    let categoryName: String
    let categoryIcon: String
    let categoryColorHex: String
    let amount: Decimal
    let transactionCount: Int
    let type: TransactionType
    
    /// Percentage of total spending/income this category represents
    var percentage: Double = 0
}

// MARK: - Daily Averages

/// Daily average calculations
struct DailyAverages: Equatable, Sendable {
    let averageIncome: Decimal
    let averageExpense: Decimal
    let averageNetChange: Decimal
    let daysInPeriod: Int
}

// MARK: - Period Type

/// Common time periods for statistics
enum StatisticsPeriod: String, CaseIterable, Sendable {
    case week
    case month
    case quarter
    case year
    case allTime
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "This Quarter"
        case .year: return "This Year"
        case .allTime: return "All Time"
        }
    }
    
    /// Get the date interval for this period
    func dateInterval(from referenceDate: Date = Date()) -> DateInterval {
        let calendar = Calendar.current
        
        switch self {
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
            return DateInterval(start: start, end: referenceDate)
            
        case .month:
            let start = calendar.dateInterval(of: .month, for: referenceDate)?.start ?? referenceDate
            return DateInterval(start: start, end: referenceDate)
            
        case .quarter:
            let start = calendar.dateInterval(of: .quarter, for: referenceDate)?.start ?? referenceDate
            return DateInterval(start: start, end: referenceDate)
            
        case .year:
            let start = calendar.dateInterval(of: .year, for: referenceDate)?.start ?? referenceDate
            return DateInterval(start: start, end: referenceDate)
            
        case .allTime:
            // Return a very long interval (10 years back)
            let start = calendar.date(byAdding: .year, value: -10, to: referenceDate) ?? referenceDate
            return DateInterval(start: start, end: referenceDate)
        }
    }
}

// MARK: - Empty Statistics

extension Statistics {
    
    /// Empty statistics for when no data is available
    static func empty(for period: DateInterval) -> Statistics {
        Statistics(
            period: period,
            totalIncome: 0,
            totalExpenses: 0,
            transactionCount: 0,
            categoryBreakdown: [],
            dailyAverages: DailyAverages(
                averageIncome: 0,
                averageExpense: 0,
                averageNetChange: 0,
                daysInPeriod: 0
            )
        )
    }
}
