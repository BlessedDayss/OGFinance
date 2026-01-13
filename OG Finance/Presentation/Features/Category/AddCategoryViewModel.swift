//
//  AddCategoryViewModel.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class AddCategoryViewModel {
    
    // MARK: - Dependencies
    
    private let categoryRepository: any CategoryRepositoryProtocol
    
    // MARK: - Input State
    
    var name: String = ""
    var icon: String = "cart.fill"
    var colorHex: String = "FF6B6B"
    var type: TransactionType = .expense
    
    // MARK: - UI State
    
    var isSaving = false
    var error: Error?
    var didSave = false
    
    // MARK: - Computed
    
    var canSave: Bool {
        !name.isEmpty && !icon.isEmpty && !colorHex.isEmpty && !isSaving
    }
    
    // MARK: - Initialization
    
    init(
        categoryRepository: any CategoryRepositoryProtocol
    ) {
        self.categoryRepository = categoryRepository
    }
    
    convenience init(container: DependencyContainer = .shared) {
        self.init(categoryRepository: container.categoryRepository)
    }
    
    // MARK: - Actions
    
    func save() async {
        guard canSave else { return }
        
        isSaving = true
        error = nil
        
        let newCategory = Category(
            name: name,
            icon: icon,
            colorHex: colorHex,
            applicableTypes: [type], // Can be extended to support both
            sortOrder: 99 // Append to end
        )
        
        do {
            try await categoryRepository.add(newCategory)
            HapticManager.shared.success()
            didSave = true
        } catch {
            self.error = error
            HapticManager.shared.error()
        }
        
        isSaving = false
    }
}
