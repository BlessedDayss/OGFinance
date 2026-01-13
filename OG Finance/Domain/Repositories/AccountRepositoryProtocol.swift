//
//  AccountRepositoryProtocol.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Protocol defining account data operations.
///
/// Accounts track balances which are updated when transactions are added/deleted.
protocol AccountRepositoryProtocol: Sendable {
    
    // MARK: - Read Operations
    
    /// Fetch all accounts, sorted by sortOrder
    func fetchAll() async throws -> [Account]
    
    /// Fetch the default account
    func fetchDefault() async throws -> Account?
    
    /// Fetch a single account by ID
    func fetch(byId id: UUID) async throws -> Account?
    
    /// Get total balance across all accounts (where includeInTotal is true)
    func totalBalance() async throws -> Decimal
    
    // MARK: - Write Operations
    
    /// Add a new account
    func add(_ account: Account) async throws
    
    /// Update an existing account
    func update(_ account: Account) async throws
    
    /// Update account balance
    /// - Parameters:
    ///   - accountId: The account to update
    ///   - delta: Amount to add (positive) or subtract (negative)
    func updateBalance(accountId: UUID, delta: Decimal) async throws
    
    /// Delete an account
    func delete(id: UUID) async throws
    
    /// Create default account if none exist
    func createDefaultIfNeeded() async throws
}
