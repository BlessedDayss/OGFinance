//
//  AddTransactionViewModel.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import Observation

/// ViewModel for the Add Transaction screen.
///
/// **State Minimization:**
/// Only the essential state is kept in this ViewModel.
/// Numeric input has its own isolated local state.
@MainActor
@Observable
final class AddTransactionViewModel {
    
    // MARK: - Dependencies
    
    private let addTransactionUseCase: any AddTransactionUseCaseProtocol
    private let categoryRepository: any CategoryRepositoryProtocol
    private let accountRepository: any AccountRepositoryProtocol
    
    // MARK: - Input State
    
    var transactionType: TransactionType
    var amount: Decimal?
    var selectedCategoryId: UUID?
    var selectedAccountId: UUID?
    var date: Date = Date()
    var note: String = ""
    
    // MARK: - UI State
    
    var categories: [Category] = []
    var accounts: [Account] = []
    var isSaving = false
    var error: Error?
    var didSave = false
    
    // MARK: - Computed
    
    var canSave: Bool {
        guard let amount = amount, amount > 0 else { return false }
        guard selectedCategoryId != nil else { return false }
        guard selectedAccountId != nil else { return false }
        return !isSaving
    }
    
    var filteredCategories: [Category] {
        categories.filter { $0.applicableTypes.contains(transactionType) }
    }
    
    // MARK: - Initialization
    
    init(
        transactionType: TransactionType = .expense,
        addTransactionUseCase: any AddTransactionUseCaseProtocol,
        categoryRepository: any CategoryRepositoryProtocol,
        accountRepository: any AccountRepositoryProtocol
    ) {
        self.transactionType = transactionType
        self.addTransactionUseCase = addTransactionUseCase
        self.categoryRepository = categoryRepository
        self.accountRepository = accountRepository
    }
    
    convenience init(
        transactionType: TransactionType = .expense,
        container: DependencyContainer = .shared
    ) {
        self.init(
            transactionType: transactionType,
            addTransactionUseCase: container.makeAddTransactionUseCase(),
            categoryRepository: container.categoryRepository,
            accountRepository: container.accountRepository
        )
    }
    
    // MARK: - Public Methods
    
    /// Load initial data (categories, accounts)
    func load() async {
        do {
            async let categoriesTask = categoryRepository.fetchAll()
            async let accountsTask = accountRepository.fetchAll()
            
            let (cats, accs) = try await (categoriesTask, accountsTask)
            
            self.categories = cats
            self.accounts = accs
            
            // Select first applicable category
            if selectedCategoryId == nil {
                selectedCategoryId = filteredCategories.first?.id
            }
            
            // Select default account
            if selectedAccountId == nil {
                selectedAccountId = accs.first(where: { $0.isDefault })?.id ?? accs.first?.id
            }
            
        } catch {
            self.error = error
        }
    }
    
    /// Toggle between income and expense
    func toggleType() {
        transactionType = transactionType == .income ? .expense : .income
        // Reset category selection for new type
        selectedCategoryId = filteredCategories.first?.id
    }
    
    /// Update the amount value (called from NumericInputField)
    func updateAmount(_ value: Decimal?) {
        self.amount = value
    }
    
    /// Save the transaction
    func save() async {
        guard canSave,
              let amount = amount,
              let categoryId = selectedCategoryId,
              let accountId = selectedAccountId else {
            return
        }
        
        isSaving = true
        error = nil
        
        do {
            try await addTransactionUseCase.execute(
                amount: amount,
                type: transactionType,
                categoryId: categoryId,
                accountId: accountId,
                date: date,
                note: note
            )
            
            didSave = true
            HapticManager.shared.success()
            
        } catch {
            self.error = error
            HapticManager.shared.error()
        }
        
        isSaving = false
    }
}
