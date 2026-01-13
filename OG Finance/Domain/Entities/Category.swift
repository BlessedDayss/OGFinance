//
//  Category.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import SwiftUI

/// Domain entity representing a transaction category.
///
/// Categories are **mutable** since users may want to:
/// - Rename categories
/// - Change icons or colors
/// - Update category ordering
///
/// - Note: Domain entities are pure Swift types with no persistence dependencies.
struct Category: Identifiable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// Unique identifier
    let id: UUID
    
    /// Display name (e.g., "Food & Dining")
    var name: String
    
    /// SF Symbol icon name
    var icon: String
    
    /// Category color as hex string (e.g., "FF6B6B")
    var colorHex: String
    
    /// Whether this category applies to income, expense, or both
    var applicableTypes: Set<TransactionType>
    
    /// Display order (lower = shown first)
    var sortOrder: Int
    
    /// Whether this is a system-provided category (cannot be deleted)
    let isSystem: Bool
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        applicableTypes: Set<TransactionType> = [.expense],
        sortOrder: Int = 0,
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.applicableTypes = applicableTypes
        self.sortOrder = sortOrder
        self.isSystem = isSystem
    }
    
    // MARK: - Computed Properties
    
    /// SwiftUI Color from hex string
    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Default Categories

extension Category {
    
    /// Pre-defined expense categories (using emojis like appDIME)
    nonisolated(unsafe) static let defaultExpenseCategories: [Category] = [
        Category(
            name: "Food & Dining",
            icon: "🍔",
            colorHex: "FF6B6B",
            applicableTypes: [.expense],
            sortOrder: 0,
            isSystem: true
        ),
        Category(
            name: "Transportation",
            icon: "🚗",
            colorHex: "4ECDC4",
            applicableTypes: [.expense],
            sortOrder: 1,
            isSystem: true
        ),
        Category(
            name: "Shopping",
            icon: "🛍️",
            colorHex: "9B59B6",
            applicableTypes: [.expense],
            sortOrder: 2,
            isSystem: true
        ),
        Category(
            name: "Entertainment",
            icon: "🎮",
            colorHex: "F39C12",
            applicableTypes: [.expense],
            sortOrder: 3,
            isSystem: true
        ),
        Category(
            name: "Bills & Utilities",
            icon: "⚡",
            colorHex: "3498DB",
            applicableTypes: [.expense],
            sortOrder: 4,
            isSystem: true
        ),
        Category(
            name: "Health",
            icon: "❤️",
            colorHex: "E74C3C",
            applicableTypes: [.expense],
            sortOrder: 5,
            isSystem: true
        ),
        Category(
            name: "Education",
            icon: "📚",
            colorHex: "1ABC9C",
            applicableTypes: [.expense],
            sortOrder: 6,
            isSystem: true
        ),
        Category(
            name: "Other",
            icon: "📦",
            colorHex: "95A5A6",
            applicableTypes: [.expense, .income],
            sortOrder: 99,
            isSystem: true
        )
    ]
    
    /// Pre-defined income categories (using emojis like appDIME)
    nonisolated(unsafe) static let defaultIncomeCategories: [Category] = [
        Category(
            name: "Salary",
            icon: "💼",
            colorHex: "00D09C",
            applicableTypes: [.income],
            sortOrder: 0,
            isSystem: true
        ),
        Category(
            name: "Freelance",
            icon: "💻",
            colorHex: "00B386",
            applicableTypes: [.income],
            sortOrder: 1,
            isSystem: true
        ),
        Category(
            name: "Investments",
            icon: "📈",
            colorHex: "2ECC71",
            applicableTypes: [.income],
            sortOrder: 2,
            isSystem: true
        ),
        Category(
            name: "Gifts",
            icon: "🎁",
            colorHex: "E91E63",
            applicableTypes: [.income],
            sortOrder: 3,
            isSystem: true
        )
    ]
    
    /// All default categories combined
    nonisolated(unsafe) static let allDefaults: [Category] = defaultExpenseCategories + defaultIncomeCategories
}
