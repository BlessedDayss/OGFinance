//
//  TransactionEntity.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftData

/// SwiftData persistence model for Transaction.
///
/// **Separation of Concerns:**
/// - Domain `Transaction` struct is pure Swift
/// - This `@Model` class handles persistence
/// - Mappers convert between the two
///
/// **Why class instead of struct?**
/// SwiftData requires reference types with `@Model` macro.
@Model
final class TransactionEntity {
    
    // MARK: - Properties
    
    /// Unique identifier
    @Attribute(.unique)
    var id: UUID
    
    /// Transaction amount (always positive)
    var amount: Decimal
    
    /// Type: "income" or "expense"
    var type: String
    
    /// Reference to category
    var categoryId: UUID
    
    /// Reference to account
    var accountId: UUID
    
    /// Transaction date
    var date: Date
    
    /// Optional note
    var note: String
    
    /// Creation timestamp
    var createdAt: Date
    
    // MARK: - Relationships
    
    /// Relationship to category entity
    @Relationship
    var category: CategoryEntity?
    
    /// Relationship to account entity
    @Relationship
    var account: AccountEntity?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        amount: Decimal,
        type: String,
        categoryId: UUID,
        accountId: UUID,
        date: Date,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.categoryId = categoryId
        self.accountId = accountId
        self.date = date
        self.note = note
        self.createdAt = createdAt
    }
}

// MARK: - Mapping Extensions

extension TransactionEntity {
    
    /// Convert to domain entity
    func toDomain() -> Transaction {
        Transaction(
            id: id,
            amount: amount,
            type: TransactionType(rawValue: type) ?? .expense,
            categoryId: categoryId,
            accountId: accountId,
            date: date,
            note: note,
            createdAt: createdAt
        )
    }
    
    /// Create from domain entity
    static func from(_ domain: Transaction) -> TransactionEntity {
        TransactionEntity(
            id: domain.id,
            amount: domain.amount,
            type: domain.type.rawValue,
            categoryId: domain.categoryId,
            accountId: domain.accountId,
            date: domain.date,
            note: domain.note,
            createdAt: domain.createdAt
        )
    }
}
