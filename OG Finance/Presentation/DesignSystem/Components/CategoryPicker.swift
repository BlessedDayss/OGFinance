//
//  CategoryPicker.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

/// Animated category picker with glass effect.
struct CategoryPicker: View {
    
    // MARK: - Properties
    
    let categories: [Category]
    @Binding var selectedCategoryId: UUID?
    let columns: Int
    
    let onAddCategory: (() -> Void)?
    
    // MARK: - Animation State
    
    @Namespace private var selectionNamespace
    
    // MARK: - Initialization
    
    init(
        categories: [Category],
        selectedCategoryId: Binding<UUID?>,
        columns: Int = 4,
        onAddCategory: (() -> Void)? = nil
    ) {
        self.categories = categories
        self._selectedCategoryId = selectedCategoryId
        self.columns = columns
        self.onAddCategory = onAddCategory
    }
    
    // MARK: - Body
    
    var body: some View {
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: OGDesign.Spacing.sm), count: columns)
        
        LazyVGrid(columns: gridColumns, spacing: OGDesign.Spacing.sm) {            
            ForEach(categories) { category in
                CategoryCell(
                    category: category,
                    isSelected: selectedCategoryId == category.id,
                    namespace: selectionNamespace
                )
                .onTapGesture {
                    withAnimation(OGDesign.Animation.springMedium) {
                        selectedCategoryId = category.id
                    }
                    HapticManager.shared.selection_()
                }
            }
            
            // Add Category Button
            if let onAddCategory {
                AddCategoryCell(action: onAddCategory)
            }
        }
    }
}

// MARK: - Add Category Cell

private struct AddCategoryCell: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: OGDesign.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(OGDesign.Colors.glassFill)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Circle()
                            .strokeBorder(OGDesign.Colors.glassBorder, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    }
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
            }
            .frame(width: 64, height: 64)
            .onTapGesture {
                HapticManager.shared.light()
                action()
            }
            
            Text("Add")
                .font(OGDesign.Typography.labelSmall)
                .foregroundStyle(OGDesign.Colors.textSecondary)
        }
    }
}

// MARK: - Category Cell

private struct CategoryCell: View {
    
    let category: Category
    let isSelected: Bool
    let namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: OGDesign.Spacing.xs) {
            ZStack {
                // Selection background (animated)
                if isSelected {
                    Circle()
                        .fill(category.color.opacity(0.3))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
                
                // Icon background
                Circle()
                    .fill(isSelected ? category.color : OGDesign.Colors.glassFill)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSelected ? category.color : OGDesign.Colors.glassBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                    .shadow(
                        color: isSelected ? category.color.opacity(0.4) : .clear,
                        radius: 8
                    )
                
                // Icon
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : category.color)
            }
            .frame(width: 64, height: 64)
            
            // Name
            Text(category.name)
                .font(OGDesign.Typography.labelSmall)
                .foregroundStyle(isSelected ? OGDesign.Colors.textPrimary : OGDesign.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(OGDesign.Animation.springQuick, value: isSelected)
    }
}
    
    // MARK: - Horizontal Scrolling Variant
    
    struct CategoryScrollPicker: View {
        
        let categories: [Category]
        @Binding var selectedCategoryId: UUID?
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: OGDesign.Spacing.sm) {
                    ForEach(categories) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategoryId == category.id
                        )
                        .onTapGesture {
                            withAnimation(OGDesign.Animation.springQuick) {
                                selectedCategoryId = category.id
                            }
                            HapticManager.shared.selection_()
                        }
                    }
                }
                .padding(.horizontal, OGDesign.Spacing.md)
            }
        }
    }
    
    // MARK: - Category Chip (for horizontal scroll)
    
    private struct CategoryChip: View {
        
        let category: Category
        let isSelected: Bool
        
        var body: some View {
            HStack(spacing: OGDesign.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(category.name)
                    .font(OGDesign.Typography.labelMedium)
            }
            .foregroundStyle(isSelected ? .white : category.color)
            .padding(.horizontal, OGDesign.Spacing.md)
            .padding(.vertical, OGDesign.Spacing.sm)
            .background {
                Capsule()
                    .fill(isSelected ? category.color : OGDesign.Colors.glassFill)
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        isSelected ? category.color : OGDesign.Colors.glassBorder,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: isSelected ? category.color.opacity(0.3) : .clear,
                radius: 6
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(OGDesign.Animation.springQuick, value: isSelected)
        }
    }
    
    // MARK: - Preview
    
    #Preview {
        ZStack {
            OGDesign.Colors.meshGradient
                .ignoresSafeArea()
            
            VStack(spacing: OGDesign.Spacing.xl) {
                // Grid picker
                GlassCard {
                    VStack(alignment: .leading, spacing: OGDesign.Spacing.md) {
                        Text("Category")
                            .font(OGDesign.Typography.labelMedium)
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                        
                        CategoryPicker(
                            categories: Category.defaultExpenseCategories,
                            selectedCategoryId: .constant(Category.defaultExpenseCategories.first?.id)
                        )
                    }
                }
                .padding(.horizontal)
                
                // Scroll picker
                VStack(alignment: .leading, spacing: OGDesign.Spacing.sm) {
                    Text("Quick Categories")
                        .font(OGDesign.Typography.labelMedium)
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .padding(.horizontal)
                    
                    CategoryScrollPicker(
                        categories: Category.defaultExpenseCategories,
                        selectedCategoryId: .constant(Category.defaultExpenseCategories[2].id)
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
    }
