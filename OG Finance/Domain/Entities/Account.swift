//
//  Account.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftUI

/// Type of financial account
enum AccountType: String, Codable, Sendable, CaseIterable {
    case checking
    case savings
    case cash
    case creditCard
    case investment
    
    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .cash: return "Cash"
        case .creditCard: return "Credit Card"
        case .investment: return "Investment"
        }
    }
    
    var iconName: String {
        switch self {
        case .checking: return "building.columns.fill"
        case .savings: return "banknote.fill"
        case .cash: return "dollarsign.circle.fill"
        case .creditCard: return "creditcard.fill"
        case .investment: return "chart.pie.fill"
        }
    }
}

/// Domain entity representing a financial account.
///
/// Accounts are **mutable** since:
/// - Balance updates with each transaction
/// - Users may rename accounts
/// - Account details may change
///
/// - Note: Domain entities are pure Swift types with no persistence dependencies.
struct Account: Identifiable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// Unique identifier
    let id: UUID
    
    /// Account name (e.g., "Main Checking")
    var name: String
    
    /// Type of account
    var type: AccountType
    
    /// Current balance (computed from transactions)
    var balance: Decimal
    
    /// Currency code (e.g., "USD", "EUR")
    var currencyCode: String
    
    /// Account color as hex string
    var colorHex: String
    
    /// Display order
    var sortOrder: Int
    
    /// Whether this is the default account for new transactions
    var isDefault: Bool
    
    /// Whether this account is included in total balance
    var includeInTotal: Bool
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        balance: Decimal = 0,
        currencyCode: String = "USD",
        colorHex: String = "007AFF",
        sortOrder: Int = 0,
        isDefault: Bool = false,
        includeInTotal: Bool = true
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.currencyCode = currencyCode
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.includeInTotal = includeInTotal
    }
    
    // MARK: - Computed Properties
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var icon: String {
        type.iconName
    }
}

// MARK: - Default Account

extension Account {
    
    /// Default account created for new users
    /// Note: Uses dynamic UUID - call createDefaultIfNeeded() to get/create account
    nonisolated(unsafe) static let defaultAccount = Account(
        name: "Main Account",
        type: .checking,
        balance: 0,
        currencyCode: "USD",
        colorHex: "007AFF",
        sortOrder: 0,
        isDefault: true,
        includeInTotal: true
    )
}
