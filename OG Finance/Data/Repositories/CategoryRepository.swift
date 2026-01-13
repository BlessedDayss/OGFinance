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
        guard count == 0 else { return }
        
        // Insert all default categories
        for category in Category.allDefaults {
            let entity = CategoryEntity.from(category)
            modelContext.insert(entity)
        }
        
        try modelContext.save()
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
