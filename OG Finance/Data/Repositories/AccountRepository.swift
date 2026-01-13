//
//  AccountRepository.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftData

/// Concrete implementation of AccountRepositoryProtocol using SwiftData.
@ModelActor
actor AccountRepository: AccountRepositoryProtocol {
    
    // MARK: - Read Operations
    
    func fetchAll() async throws -> [Account] {
        let descriptor = FetchDescriptor<AccountEntity>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    func fetchDefault() async throws -> Account? {
        let predicate = #Predicate<AccountEntity> { entity in
            entity.isDefault == true
        }
        
        var descriptor = FetchDescriptor<AccountEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        return entities.first?.toDomain()
    }
    
    func fetch(byId id: UUID) async throws -> Account? {
        let targetId: UUID = id
        
        let predicate = #Predicate<AccountEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<AccountEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        return entities.first?.toDomain()
    }
    
    func totalBalance() async throws -> Decimal {
        let predicate = #Predicate<AccountEntity> { entity in
            entity.includeInTotal == true
        }
        
        let descriptor = FetchDescriptor<AccountEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        
        return entities.reduce(Decimal.zero) { $0 + $1.balance }
    }
    
    // MARK: - Write Operations
    
    func add(_ account: Account) async throws {
        let entity = AccountEntity.from(account)
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func update(_ account: Account) async throws {
        let targetId: UUID = account.id
        
        let predicate = #Predicate<AccountEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<AccountEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        if let entity = entities.first {
            entity.update(from: account)
            try modelContext.save()
        }
    }
    
    func updateBalance(accountId: UUID, delta: Decimal) async throws {
        let targetId: UUID = accountId
        
        let predicate = #Predicate<AccountEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<AccountEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        if let entity = entities.first {
            entity.balance += delta
            try modelContext.save()
        }
    }
    
    func delete(id: UUID) async throws {
        let targetId: UUID = id
        
        let predicate = #Predicate<AccountEntity> { entity in
            entity.id == targetId
        }
        
        var descriptor = FetchDescriptor<AccountEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let entities = try modelContext.fetch(descriptor)
        if let entity = entities.first {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }
    
    func createDefaultIfNeeded() async throws {
        let descriptor = FetchDescriptor<AccountEntity>()
        let count = try modelContext.fetchCount(descriptor)
        
        guard count == 0 else { return }
        
        let defaultAccount = AccountEntity.from(Account.defaultAccount)
        modelContext.insert(defaultAccount)
        try modelContext.save()
    }
}
