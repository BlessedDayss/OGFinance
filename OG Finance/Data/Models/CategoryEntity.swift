//
//  CategoryEntity.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftData

/// SwiftData persistence model for Category.
@Model
final class CategoryEntity {
    
    // MARK: - Properties
    
    @Attribute(.unique)
    var id: UUID
    
    var name: String
    var icon: String
    var colorHex: String
    
    /// Comma-separated list of applicable types ("income", "expense", or "income,expense")
    var applicableTypesRaw: String
    
    var sortOrder: Int
    var isSystem: Bool
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .nullify, inverse: \TransactionEntity.category)
    var transactions: [TransactionEntity]?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        applicableTypesRaw: String,
        sortOrder: Int = 0,
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.applicableTypesRaw = applicableTypesRaw
        self.sortOrder = sortOrder
        self.isSystem = isSystem
    }
}

// MARK: - Mapping Extensions

extension CategoryEntity {
    
    /// Convert to domain entity
    func toDomain() -> Category {
        let types = applicableTypesRaw
            .split(separator: ",")
            .compactMap { TransactionType(rawValue: String($0)) }
        
        return Category(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            applicableTypes: Set(types),
            sortOrder: sortOrder,
            isSystem: isSystem
        )
    }
    
    /// Create from domain entity
    static func from(_ domain: Category) -> CategoryEntity {
        let typesRaw = domain.applicableTypes
            .map { $0.rawValue }
            .sorted()
            .joined(separator: ",")
        
        return CategoryEntity(
            id: domain.id,
            name: domain.name,
            icon: domain.icon,
            colorHex: domain.colorHex,
            applicableTypesRaw: typesRaw,
            sortOrder: domain.sortOrder,
            isSystem: domain.isSystem
        )
    }
    
    /// Update from domain entity
    func update(from domain: Category) {
        name = domain.name
        icon = domain.icon
        colorHex = domain.colorHex
        applicableTypesRaw = domain.applicableTypes
            .map { $0.rawValue }
            .sorted()
            .joined(separator: ",")
        sortOrder = domain.sortOrder
    }
}
