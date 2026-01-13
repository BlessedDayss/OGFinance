//
//  DeleteTransactionUseCase.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Protocol for deleting transactions.
protocol DeleteTransactionUseCaseProtocol: Sendable {
    
    /// Delete a transaction and reverse its balance effect
    /// - Parameter id: Transaction ID to delete
    func execute(id: UUID) async throws
}

/// Concrete implementation of DeleteTransactionUseCase.
///
/// **Business Logic:**
/// 1. Fetches the transaction to get the amount
/// 2. Reverses the balance effect on the account
/// 3. Deletes the transaction
final class DeleteTransactionUseCase: DeleteTransactionUseCaseProtocol {
    
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
    
    func execute(id: UUID) async throws {
        // Fetch the transaction to get its details
        guard let transaction = try await transactionRepository.fetch(byId: id) else {
            throw TransactionError.transactionNotFound
        }
        
        // Reverse the balance effect (negate the signed amount)
        let reverseDelta = -transaction.signedAmount
        try await accountRepository.updateBalance(accountId: transaction.accountId, delta: reverseDelta)
        
        // Delete the transaction
        try await transactionRepository.delete(id: id)
    }
}
