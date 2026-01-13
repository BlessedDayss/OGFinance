//
//  AccountEntity.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftData

/// SwiftData persistence model for Account.
@Model
final class AccountEntity {
    
    // MARK: - Properties
    
    @Attribute(.unique)
    var id: UUID
    
    var name: String
    var type: String // AccountType raw value
    var balance: Decimal
    var currencyCode: String
    var colorHex: String
    var sortOrder: Int
    var isDefault: Bool
    var includeInTotal: Bool
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .nullify, inverse: \TransactionEntity.account)
    var transactions: [TransactionEntity]?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        type: String,
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
}

// MARK: - Mapping Extensions

extension AccountEntity {
    
    /// Convert to domain entity
    func toDomain() -> Account {
        Account(
            id: id,
            name: name,
            type: AccountType(rawValue: type) ?? .checking,
            balance: balance,
            currencyCode: currencyCode,
            colorHex: colorHex,
            sortOrder: sortOrder,
            isDefault: isDefault,
            includeInTotal: includeInTotal
        )
    }
    
    /// Create from domain entity
    static func from(_ domain: Account) -> AccountEntity {
        AccountEntity(
            id: domain.id,
            name: domain.name,
            type: domain.type.rawValue,
            balance: domain.balance,
            currencyCode: domain.currencyCode,
            colorHex: domain.colorHex,
            sortOrder: domain.sortOrder,
            isDefault: domain.isDefault,
            includeInTotal: domain.includeInTotal
        )
    }
    
    /// Update from domain entity
    func update(from domain: Account) {
        name = domain.name
        type = domain.type.rawValue
        balance = domain.balance
        currencyCode = domain.currencyCode
        colorHex = domain.colorHex
        sortOrder = domain.sortOrder
        isDefault = domain.isDefault
        includeInTotal = domain.includeInTotal
    }
}
