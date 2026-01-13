//
//  CategoryRepository.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftData

/// Concrete implementation of CategoryRepositoryProtocol using SwiftData.
@ModelActor
actor CategoryRepository: CategoryRepositoryProtocol {
    
    // MARK: - Read Operations
    
    func fetchAll() async throws -> [Category] {
        let descriptor = FetchDescriptor<CategoryEntity>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    func fetch(for type: TransactionType) async throws -> [Category] {
        let typeRaw = type.rawValue
        
        let predicate = #Predicate<CategoryEntity> { entity in
            entity.applicableTypesRaw.contains(typeRaw)
        }
        
        var descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.sortOrder)]
        
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    func fetch(byId id: UUID) async throws -> Category? {
        // Capture id in local variable for predicate
        let targetId: UUID = id
        
        let predicate = #Predicate<CategoryEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        return entities.first?.toDomain()
    }
    
    // MARK: - Write Operations
    
    func add(_ category: Category) async throws {
        let entity = CategoryEntity.from(category)
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func update(_ category: Category) async throws {
        // Capture id in local variable for predicate
        let targetId: UUID = category.id
        
        let predicate = #Predicate<CategoryEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        if let entity = entities.first {
            entity.update(from: category)
            try modelContext.save()
        }
    }
    
    func delete(id: UUID) async throws {
        // Capture id in local variable for predicate
        let targetId: UUID = id
        
        let predicate = #Predicate<CategoryEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        if let entity = entities.first {
            // Prevent deletion of system categories
            guard !entity.isSystem else {
                throw CategoryError.cannotDeleteSystemCategory
            }
            modelContext.delete(entity)
            try modelContext.save()
        }
    }
    
    func seedDefaultsIfNeeded() async throws {
        let descriptor = FetchDescriptor<CategoryEntity>()
        let count = try modelContext.fetchCount(descriptor)
        
        // Only seed if no categories exist
        guard count == 0 else {
            // Migrate existing categories to use emojis if needed
            try await migrateIconsToEmojis()
            return
        }
        
        // Insert all default categories
        for category in Category.allDefaults {
            let entity = CategoryEntity.from(category)
            modelContext.insert(entity)
        }
        
        try modelContext.save()
    }
    
    /// Migrate old SF Symbol icons to emojis
    private func migrateIconsToEmojis() async throws {
        let descriptor = FetchDescriptor<CategoryEntity>()
        let entities = try modelContext.fetch(descriptor)
        
        // Mapping from SF Symbol names to emojis
        let iconMapping: [String: String] = [
            // Expense categories
            "cart.fill": "🛍️",
            "cart": "🛍️",
            "fork.knife": "🍔",
            "fork.knife.circle.fill": "🍔",
            "car.fill": "🚗",
            "car": "🚗",
            "gamecontroller.fill": "🎮",
            "gamecontroller": "🎮",
            "bolt.fill": "⚡",
            "bolt": "⚡",
            "heart.fill": "❤️",
            "heart": "❤️",
            "book.fill": "📚",
            "book": "📚",
            "cube.box.fill": "📦",
            "cube.box": "📦",
            "shippingbox.fill": "📦",
            "shippingbox": "📦",
            "house.fill": "🏠",
            "house": "🏠",
            "airplane": "✈️",
            "tram.fill": "🚃",
            "bus.fill": "🚌",
            "figure.walk": "🚶",
            "creditcard.fill": "💳",
            "creditcard": "💳",
            "bag.fill": "👜",
            "bag": "👜",
            
            // Income categories
            "briefcase.fill": "💼",
            "briefcase": "💼",
            "laptopcomputer": "💻",
            "macbook": "💻",
            "desktopcomputer": "💻",
            "pc": "💻",
            "chart.line.uptrend.xyaxis": "📈",
            "chart.xyaxis.line": "📈",
            "arrow.up.right": "📈",
            "gift.fill": "🎁",
            "gift": "🎁",
            "giftcard.fill": "🎁",
            "giftcard": "🎁",
            "dollarsign.circle.fill": "💰",
            "dollarsign.circle": "💰",
            "dollarsign": "💰",
            "banknote.fill": "💵",
            "banknote": "💵",
            "building.columns.fill": "🏦",
            "building.columns": "🏦",
            "building.2.fill": "🏢",
            "building.2": "🏢",
            
            // Other common icons
            "ellipsis.circle.fill": "📦",
            "ellipsis.circle": "📦",
            "questionmark.circle.fill": "❓",
            "questionmark.circle": "❓"
        ]
        
        var needsSave = false
        
        for entity in entities {
            // Check if icon needs migration:
            // 1. Contains "." (SF Symbol with dots)
            // 2. Is in our mapping (SF Symbols without dots like "laptopcomputer")
            // 3. Is longer than 2 chars and not an emoji
            let needsMigration = entity.icon.contains(".") || 
                                 iconMapping[entity.icon] != nil ||
                                 (entity.icon.count > 2 && !entity.icon.unicodeScalars.first!.properties.isEmoji)
            
            if needsMigration {
                if let emojiIcon = iconMapping[entity.icon] {
                    print("🔄 Migrating icon: \(entity.icon) → \(emojiIcon)")
                    entity.icon = emojiIcon
                    needsSave = true
                } else if entity.icon.count > 2 && !entity.icon.unicodeScalars.first!.properties.isEmoji {
                    // Unknown SF Symbol - use default
                    print("⚠️ Unknown icon: \(entity.icon) → 📦")
                    entity.icon = "📦"
                    needsSave = true
                }
            }
        }
        
        if needsSave {
            try modelContext.save()
            print("✅ Icon migration completed")
        }
    }
}

// MARK: - Errors

enum CategoryError: LocalizedError {
    case cannotDeleteSystemCategory
    
    var errorDescription: String? {
        switch self {
        case .cannotDeleteSystemCategory:
            return "System categories cannot be deleted"
        }
    }
}
