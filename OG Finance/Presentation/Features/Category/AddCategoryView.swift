//
//  AddCategoryView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

struct AddCategoryView: View {
    
    // MARK: - State
    
    @State private var viewModel = AddCategoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var hasAppeared = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AnimatedMeshBackground()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: OGDesign.Spacing.lg) {
                        
                        // Preview Header
                        headerPreview
                            .offset(y: hasAppeared ? 0 : 30)
                            .opacity(hasAppeared ? 1 : 0)
                        
                        // Form Fields
                        VStack(spacing: OGDesign.Spacing.lg) {
                            
                            // Name Input
                            GlassCard {
                                TextField("Category Name", text: $viewModel.name)
                                    .font(OGDesign.Typography.headlineSmall)
                                    .foregroundStyle(OGDesign.Colors.textPrimary)
                                    .padding(.vertical, OGDesign.Spacing.xs)
                            }
                            
                            // Type Picker
                            GlassCard(padding: 4) {
                                Picker("Type", selection: $viewModel.type) {
                                    Text("Expense").tag(TransactionType.expense)
                                    Text("Income").tag(TransactionType.income)
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Color Picker
                            VStack(alignment: .leading, spacing: OGDesign.Spacing.sm) {
                                Text("Color")
                                    .font(OGDesign.Typography.labelMedium)
                                    .foregroundStyle(OGDesign.Colors.textSecondary)
                                    .padding(.horizontal)
                                
                                GlassCard(padding: 0) {
                                    CategoryColorPicker(selectedColorHex: $viewModel.colorHex)
                                }
                            }
                            
                            // Icon Picker
                            VStack(alignment: .leading, spacing: OGDesign.Spacing.sm) {
                                Text("Icon")
                                    .font(OGDesign.Typography.labelMedium)
                                    .foregroundStyle(OGDesign.Colors.textSecondary)
                                    .padding(.horizontal)
                                
                                GlassCard(padding: 0) {
                                    CategoryIconPicker(
                                        selectedIcon: $viewModel.icon,
                                        selectedColor: Color(hex: viewModel.colorHex)
                                    )
                                }
                            }
                            
                            // Save Button
                            GlassButton(
                                "Create Category",
                                icon: "checkmark",
                                style: .primary,
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
                        .offset(y: hasAppeared ? 0 : 30)
                        .opacity(hasAppeared ? 1 : 0)
                    }
                    .padding()
                    .padding(.bottom, OGDesign.Spacing.xl)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                }
            }
        }
        .onAppear {
            withAnimation(OGDesign.Animation.springMedium) {
                hasAppeared = true
            }
        }
        .onChange(of: viewModel.didSave) { _, didSave in
            if didSave {
                dismiss()
            }
        }
    }
    
    // MARK: - Header Preview
    
    private var headerPreview: some View {
        VStack(spacing: OGDesign.Spacing.sm) {
            // Big Icon Preview
            Circle()
                .fill(Color(hex: viewModel.colorHex).opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: viewModel.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hex: viewModel.colorHex))
                }
                .overlay {
                    Circle()
                        .strokeBorder(Color(hex: viewModel.colorHex).opacity(0.5), lineWidth: 1)
                }
                .shadow(color: Color(hex: viewModel.colorHex).opacity(0.3), radius: 20)
            
            Text(viewModel.name.isEmpty ? "Category Name" : viewModel.name)
                .font(OGDesign.Typography.headlineMedium)
                .foregroundStyle(OGDesign.Colors.textPrimary)
        }
        .padding(.vertical, OGDesign.Spacing.lg)
    }
}

#Preview {
    AddCategoryView()
        .preferredColorScheme(.dark)
}
