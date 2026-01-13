//
//  Transaction.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Domain entity representing a financial transaction.
///
/// This is an **immutable** value type by design:
/// - Financial records should never be edited after creation
/// - Corrections are made by creating reversal/void transactions
/// - Immutability ensures data integrity and audit trail
///
/// - Note: Domain entities are pure Swift types with no persistence dependencies.
struct Transaction: Identifiable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// Unique identifier for this transaction
    let id: UUID
    
    /// Transaction amount (always positive, type determines direction)
    let amount: Decimal
    
    /// Whether this is income or expense
    let type: TransactionType
    
    /// Reference to the category this transaction belongs to
    let categoryId: UUID
    
    /// Reference to the account this transaction affects
    let accountId: UUID
    
    /// The date when this transaction occurred
    let date: Date
    
    /// Optional note or memo
    let note: String
    
    /// Timestamp when this transaction was created in the system
    let createdAt: Date
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        amount: Decimal,
        type: TransactionType,
        categoryId: UUID,
        accountId: UUID,
        date: Date,
        note: String = "",
        createdAt: Date = Date()
    ) {
        // Ensure amount is always stored as positive and within safe bounds
        let maxAllowedAmount = Decimal(string: "999999999999.99")!
        self.id = id
        self.amount = min(abs(amount), maxAllowedAmount)
        self.type = type
        self.categoryId = categoryId
        self.accountId = accountId
        self.date = date
        self.note = note
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    /// Signed amount for balance calculations
    /// - Returns: Positive for income, negative for expense
    var signedAmount: Decimal {
        amount * type.balanceMultiplier
    }
}

// MARK: - Comparable

extension Transaction: Comparable {
    static func < (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.date > rhs.date // Most recent first
    }
}
