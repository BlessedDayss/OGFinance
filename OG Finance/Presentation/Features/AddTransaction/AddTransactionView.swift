//
//  AddTransactionView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

/// Full-screen sheet for adding new transactions.
///
/// **Keyboard Optimization:**
/// The NumericInputField has isolated local state.
/// This view doesn't re-render on every keystroke.
struct AddTransactionView: View {
    
    // MARK: - ViewModel
    
    @State private var viewModel: AddTransactionViewModel
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Callbacks
    
    let onSave: () -> Void
    
    // MARK: - Animation State
    
    @State private var hasAppeared = false
    @State private var showAddCategory = false
    
    // MARK: - Initialization
    
    init(
        transactionType: TransactionType = .expense,
        onSave: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: AddTransactionViewModel(transactionType: transactionType))
        self.onSave = onSave
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                background
                
                // Content
                VStack(spacing: 0) {
                    // Type toggle (Fixed)
                    typeToggle
                        .padding(.horizontal)
                        .padding(.top, OGDesign.Spacing.md)
                        .padding(.bottom, OGDesign.Spacing.sm)
                        .offset(y: hasAppeared ? 0 : -30) // Slide down animation
                        .opacity(hasAppeared ? 1 : 0)
                        
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: OGDesign.Spacing.lg) {
                            
                            // Amount input
                            amountSection
                                .offset(y: hasAppeared ? 0 : 30)
                                .opacity(hasAppeared ? 1 : 0)
                        
                        // Category selection
                        categorySection
                            .offset(y: hasAppeared ? 0 : 30)
                            .opacity(hasAppeared ? 1 : 0)
                        
                        // Date & Note
                        detailsSection
                            .offset(y: hasAppeared ? 0 : 30)
                            .opacity(hasAppeared ? 1 : 0)
                        
                        // Save button
                        saveButton
                            .offset(y: hasAppeared ? 0 : 30)
                            .opacity(hasAppeared ? 1 : 0)
                    }
                    .padding()
                    .padding(.bottom, OGDesign.Spacing.xl)
                }
            }
        }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                }
            }
        }
        .task {
            await viewModel.load()
            withAnimation(OGDesign.Animation.springMedium.delay(0.1)) {
                hasAppeared = true
            }
        }
        .onChange(of: viewModel.didSave) { _, didSave in
            if didSave {
                onSave()
                dismiss()
            }
        }
    }
    
    // MARK: - Background
    
    private var background: some View {
        ZStack {
            OGDesign.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            // Type-specific glow
            Circle()
                .fill(
                    viewModel.transactionType == .income
                        ? OGDesign.Colors.income.opacity(0.15)
                        : OGDesign.Colors.expense.opacity(0.15)
                )
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(y: -150)
                .animation(OGDesign.Animation.springMedium, value: viewModel.transactionType)
        }
    }
    
    // MARK: - Type Toggle
    
    // MARK: - Type Toggle
    
    private var typeToggle: some View {
        GeometryReader { geometry in
            let capsuleWidth = (geometry.size.width - 2 * OGDesign.Spacing.xs) / 2
            
            ZStack(alignment: .leading) {
                // Sliding Capsule
                Capsule()
                    .fill(OGDesign.Colors.glassFill)
                    .frame(width: capsuleWidth)
                    .offset(x: viewModel.transactionType == .income ? capsuleWidth : 0)
                    .animation(OGDesign.Animation.springQuick, value: viewModel.transactionType)
                
                HStack(spacing: 0) {
                    // Expense Button
                    Button {
                        withAnimation(OGDesign.Animation.springQuick) {
                            viewModel.transactionType = .expense
                        }
                        HapticManager.shared.transactionTypeToggle()
                    } label: {
                        Text("Expense")
                            .font(OGDesign.Typography.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(viewModel.transactionType == .expense ? OGDesign.Colors.textPrimary : OGDesign.Colors.textSecondary)
                            .frame(width: capsuleWidth)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Income Button
                    Button {
                        withAnimation(OGDesign.Animation.springQuick) {
                            viewModel.transactionType = .income
                        }
                        HapticManager.shared.transactionTypeToggle()
                    } label: {
                        Text("Income")
                            .font(OGDesign.Typography.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(viewModel.transactionType == .income ? OGDesign.Colors.textPrimary : OGDesign.Colors.textSecondary)
                            .frame(width: capsuleWidth)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(OGDesign.Spacing.xs)
            .background(
                Capsule()
                    .stroke(OGDesign.Colors.glassBorder, lineWidth: 1)
            )
        }
        .frame(height: 50)
    }
    
    // MARK: - Amount Section
    
    private var amountSection: some View {
        GlassCard {
            VStack(spacing: OGDesign.Spacing.sm) {
                Text(viewModel.transactionType.displayName.uppercased())
                    .font(OGDesign.Typography.labelSmall)
                    .foregroundStyle(OGDesign.Colors.textTertiary)
                    .tracking(1.5)
                
                NumericInputField(
                    transactionType: viewModel.transactionType,
                    onValueChange: { value in
                        viewModel.updateAmount(value)
                    }
                )
            }
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: OGDesign.Spacing.sm) {
            Text("Category")
                .font(OGDesign.Typography.labelMedium)
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .padding(.horizontal, OGDesign.Spacing.xs)
            
            GlassCard {
                CategoryPicker(
                    categories: viewModel.filteredCategories,
                    selectedCategoryId: $viewModel.selectedCategoryId,
                    onAddCategory: {
                        showAddCategory = true
                    }
                )
            }
        }
        .sheet(isPresented: $showAddCategory) {
            // Reload categories on dismiss
            Task {
                await viewModel.load()
            }
        } content: {
            AddCategoryView()
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(spacing: OGDesign.Spacing.md) {
            // Date picker
            GlassCard {
                DatePicker(
                    "Date",
                    selection: $viewModel.date,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .tint(
                    viewModel.transactionType == .income
                        ? OGDesign.Colors.income
                        : OGDesign.Colors.expense
                )
            }
            
            // Note field
            GlassCard {
                VStack(alignment: .leading, spacing: OGDesign.Spacing.xs) {
                    Text("Note (optional)")
                        .font(OGDesign.Typography.labelSmall)
                        .foregroundStyle(OGDesign.Colors.textTertiary)
                    
                    TextField("Add a note...", text: $viewModel.note)
                        .font(OGDesign.Typography.bodyLarge)
                        .foregroundStyle(OGDesign.Colors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        GlassButton(
            "Save Transaction",
            icon: "checkmark",
            style: viewModel.transactionType == .income ? .income : .expense,
            size: .large,
            isFullWidth: true,
            isLoading: viewModel.isSaving
        ) {
            Task {
                await viewModel.save()
            }
        }
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : 0.5)
    }
}

// MARK: - Preview

#Preview {
    AddTransactionView()
        .preferredColorScheme(.dark)
}
