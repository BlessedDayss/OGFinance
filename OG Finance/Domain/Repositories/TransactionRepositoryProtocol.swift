//
//  TransactionRepositoryProtocol.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Protocol defining transaction data operations.
///
/// **Dependency Inversion Principle (SOLID-D)**:
/// - Domain layer defines this interface
/// - Data layer provides implementation
/// - Use cases depend on abstraction, not concrete SwiftData types
///
/// **Interface Segregation (SOLID-I)**:
/// Combined from `TransactionReader` and `TransactionWriter` protocols
protocol TransactionRepositoryProtocol: Sendable {
    
    // MARK: - Read Operations
    
    /// Fetch all transactions, sorted by date (most recent first)
    func fetchAll() async throws -> [Transaction]
    
    /// Fetch transactions within a specific date range
    /// - Parameter period: The date interval to filter by
    func fetch(for period: DateInterval) async throws -> [Transaction]
    
    /// Fetch transactions for a specific account
    /// - Parameter accountId: The account to filter by
    func fetch(forAccount accountId: UUID) async throws -> [Transaction]
    
    /// Fetch transactions for a specific category
    /// - Parameter categoryId: The category to filter by
    func fetch(forCategory categoryId: UUID) async throws -> [Transaction]
    
    /// Fetch a single transaction by ID
    /// - Parameter id: Transaction identifier
    func fetch(byId id: UUID) async throws -> Transaction?
    
    /// Get the count of transactions
    func count() async throws -> Int
    
    // MARK: - Write Operations
    
    /// Add a new transaction
    /// - Parameter transaction: The transaction to persist
    func add(_ transaction: Transaction) async throws
    
    /// Add multiple transactions in batch
    /// - Parameter transactions: Array of transactions to persist
    func addBatch(_ transactions: [Transaction]) async throws
    
    /// Delete a transaction
    /// - Parameter id: Transaction identifier to delete
    func delete(id: UUID) async throws
    
    /// Delete all transactions (for testing/reset)
    func deleteAll() async throws
}

// MARK: - Optional Reader/Writer Segregation

/// Read-only transaction operations (Interface Segregation)
protocol TransactionReader: Sendable {
    func fetchAll() async throws -> [Transaction]
    func fetch(for period: DateInterval) async throws -> [Transaction]
    func fetch(byId id: UUID) async throws -> Transaction?
}

/// Write transaction operations (Interface Segregation)
protocol TransactionWriter: Sendable {
    func add(_ transaction: Transaction) async throws
    func delete(id: UUID) async throws
}
