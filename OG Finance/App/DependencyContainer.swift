//
//  DependencyContainer.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftData

/// Dependency Injection container for the application.
///
/// **Purpose:**
/// - Centralized creation of all dependencies
/// - Easy to swap implementations (e.g., mocks for testing)
/// - Follows Dependency Inversion Principle
///
/// **Pattern:**
/// Factory pattern - creates dependencies on demand.
/// Uses `@Observable` for SwiftUI integration.
///
/// **Thread Safety:**
/// Uses `@MainActor` since most consumers are Views/ViewModels.
@MainActor
@Observable
final class DependencyContainer {
    
    // MARK: - Shared Instance
    
    static let shared = DependencyContainer()
    
    // MARK: - Core Dependencies
    
    /// SwiftData model container
    let modelContainer: ModelContainer
    
    // MARK: - Cached Repositories
    
    private var _transactionRepository: (any TransactionRepositoryProtocol)?
    private var _categoryRepository: (any CategoryRepositoryProtocol)?
    private var _accountRepository: (any AccountRepositoryProtocol)?
    
    // MARK: - Initialization
    
    private init() {
        // Configure SwiftData schema
        let schema = Schema([
            TransactionEntity.self,
            CategoryEntity.self,
            AccountEntity.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Repository Factories
    
    /// Transaction repository (cached)
    var transactionRepository: any TransactionRepositoryProtocol {
        if let repo = _transactionRepository {
            return repo
        }
        let repo = TransactionRepository(modelContainer: modelContainer)
        _transactionRepository = repo
        return repo
    }
    
    /// Category repository (cached)
    var categoryRepository: any CategoryRepositoryProtocol {
        if let repo = _categoryRepository {
            return repo
        }
        let repo = CategoryRepository(modelContainer: modelContainer)
        _categoryRepository = repo
        return repo
    }
    
    /// Account repository (cached)
    var accountRepository: any AccountRepositoryProtocol {
        if let repo = _accountRepository {
            return repo
        }
        let repo = AccountRepository(modelContainer: modelContainer)
        _accountRepository = repo
        return repo
    }
    
    // MARK: - Use Case Factories
    
    /// Create AddTransactionUseCase
    func makeAddTransactionUseCase() -> any AddTransactionUseCaseProtocol {
        AddTransactionUseCase(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository
        )
    }
    
    /// Create DeleteTransactionUseCase
    func makeDeleteTransactionUseCase() -> any DeleteTransactionUseCaseProtocol {
        DeleteTransactionUseCase(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository
        )
    }
    
    /// Create GetStatisticsUseCase
    func makeGetStatisticsUseCase() -> any GetStatisticsUseCaseProtocol {
        GetStatisticsUseCase(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository
        )
    }
    
    // MARK: - Initialization Tasks
    
    /// Initialize default data (categories, account)
    /// Call this on app launch
    func initializeDefaults() async {
        do {
            try await categoryRepository.seedDefaultsIfNeeded()
            try await accountRepository.createDefaultIfNeeded()
        } catch {
            print("Failed to initialize defaults: \(error)")
        }
    }
}

// MARK: - Testing Support

extension DependencyContainer {
    
    /// Create a container for testing with in-memory storage
    static func forTesting() -> DependencyContainer {
        // For testing, we'd create a separate instance with mocks
        // This is a placeholder - actual implementation would use protocol-based DI
        return .shared
    }
}
