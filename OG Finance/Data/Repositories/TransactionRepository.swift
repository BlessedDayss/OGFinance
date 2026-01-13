//
//  TransactionRepository.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftData

/// Concrete implementation of TransactionRepositoryProtocol using SwiftData.
///
/// **Actor isolation:**
/// SwiftData's ModelContext is not Sendable, so we use @ModelActor
/// to ensure all operations happen on the same isolated context.
///
/// **Liskov Substitution (SOLID-L):**
/// This can be swapped with MockTransactionRepository for testing.
@ModelActor
actor TransactionRepository: TransactionRepositoryProtocol {
    
    // MARK: - Read Operations
    
    func fetchAll() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    func fetch(for period: DateInterval) async throws -> [Transaction] {
        let startDate = period.start
        let endDate = period.end
        
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.date >= startDate && entity.date <= endDate
        }
        
        var descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    func fetch(forAccount accountId: UUID) async throws -> [Transaction] {
        let targetAccountId: UUID = accountId
        
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.accountId == targetAccountId
        }
        
        var descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    func fetch(forCategory categoryId: UUID) async throws -> [Transaction] {
        let targetCategoryId: UUID = categoryId
        
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.categoryId == targetCategoryId
        }
        
        var descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    func fetch(byId id: UUID) async throws -> Transaction? {
        let targetId: UUID = id
        
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        return entities.first?.toDomain()
    }
    
    func count() async throws -> Int {
        let descriptor = FetchDescriptor<TransactionEntity>()
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - Write Operations
    
    func add(_ transaction: Transaction) async throws {
        let entity = TransactionEntity.from(transaction)
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func addBatch(_ transactions: [Transaction]) async throws {
        for transaction in transactions {
            let entity = TransactionEntity.from(transaction)
            modelContext.insert(entity)
        }
        try modelContext.save()
    }
    
    func delete(id: UUID) async throws {
        let targetId: UUID = id
        
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        if let entity = entities.first {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }
    
    func deleteAll() async throws {
        try modelContext.delete(model: TransactionEntity.self)
        try modelContext.save()
    }
}
