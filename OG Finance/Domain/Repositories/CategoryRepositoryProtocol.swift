//
//  CategoryRepositoryProtocol.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Protocol defining category data operations.
///
/// Categories are mutable entities that users can customize.
/// Default categories are seeded on first launch.
protocol CategoryRepositoryProtocol: Sendable {
    
    // MARK: - Read Operations
    
    /// Fetch all categories, sorted by sortOrder
    func fetchAll() async throws -> [Category]
    
    /// Fetch categories applicable to a specific transaction type
    /// - Parameter type: Income or Expense
    func fetch(for type: TransactionType) async throws -> [Category]
    
    /// Fetch a single category by ID
    func fetch(byId id: UUID) async throws -> Category?
    
    // MARK: - Write Operations
    
    /// Add a new category
    func add(_ category: Category) async throws
    
    /// Update an existing category
    func update(_ category: Category) async throws
    
    /// Delete a category (fails for system categories)
    func delete(id: UUID) async throws
    
    /// Seed default categories if none exist
    func seedDefaultsIfNeeded() async throws
}
