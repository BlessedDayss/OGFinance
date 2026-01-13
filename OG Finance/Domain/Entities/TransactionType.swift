//
//  TransactionType.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Represents the type of financial transaction.
/// - Note: This is a domain-level type, independent of persistence layer.
enum TransactionType: String, Codable, Sendable, CaseIterable {
    case income
    case expense
    
    /// User-facing display name
    var displayName: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
    
    /// Multiplier for balance calculations
    /// - Returns: 1 for income (adds to balance), -1 for expense (subtracts from balance)
    var balanceMultiplier: Decimal {
        switch self {
        case .income: return 1
        case .expense: return -1
        }
    }
}
