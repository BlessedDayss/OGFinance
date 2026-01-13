//
//  AddTransactionUseCase.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Protocol for adding transactions.
///
/// **Single Responsibility (SOLID-S):**
/// This use case has one job: orchestrate the creation of a transaction.
///
/// **Dependency Inversion (SOLID-D):**
/// Depends on repository protocols, not concrete implementations.
protocol AddTransactionUseCaseProtocol: Sendable {
    
    /// Execute the use case to add a transaction
    /// - Parameters:
    ///   - amount: Transaction amount (positive)
    ///   - type: Income or expense
    ///   - categoryId: Category for this transaction
    ///   - accountId: Account to update
    ///   - date: Transaction date
    ///   - note: Optional note
    /// - Returns: The created transaction
    @discardableResult
    func execute(
        amount: Decimal,
        type: TransactionType,
        categoryId: UUID,
        accountId: UUID,
        date: Date,
        note: String
    ) async throws -> Transaction
}

/// Concrete implementation of AddTransactionUseCase.
///
/// **Business Logic:**
/// 1. Creates the transaction
/// 2. Updates the account balance
/// 3. This is atomic - if one fails, nothing persists
final class AddTransactionUseCase: AddTransactionUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let transactionRepository: any TransactionRepositoryProtocol
    private let accountRepository: any AccountRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        transactionRepository: any TransactionRepositoryProtocol,
        accountRepository: any AccountRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
    }
    
    // MARK: - Execution
    
    @discardableResult
    func execute(
        amount: Decimal,
        type: TransactionType,
        categoryId: UUID,
        accountId: UUID,
        date: Date,
        note: String
    ) async throws -> Transaction {
        // Validate amount
        guard amount > 0 else {
            throw TransactionError.invalidAmount
        }
        
        // Verify account exists
        guard await (try? accountRepository.fetch(byId: accountId)) != nil else {
            throw TransactionError.accountNotFound
        }
        
        // Create transaction
        let transaction = Transaction(
            amount: amount,
            type: type,
            categoryId: categoryId,
            accountId: accountId,
            date: date,
            note: note
        )
        
        // Persist transaction
        try await transactionRepository.add(transaction)
        
        // Update account balance
        let balanceDelta = transaction.signedAmount
        try await accountRepository.updateBalance(accountId: accountId, delta: balanceDelta)
        
        return transaction
    }
}

// MARK: - Errors

enum TransactionError: LocalizedError {
    case invalidAmount
    case accountNotFound
    case categoryNotFound
    case transactionNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Amount must be greater than zero"
        case .accountNotFound:
            return "Account not found"
        case .categoryNotFound:
            return "Category not found"
        case .transactionNotFound:
            return "Transaction not found"
        }
    }
}
