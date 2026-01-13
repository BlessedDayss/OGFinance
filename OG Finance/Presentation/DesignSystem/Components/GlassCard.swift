//
//  GlassCard.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

/// A reusable glass effect card component.
///
/// **iOS 26 Glass Effect:**
/// Uses the native `.glassEffect()` modifier for authentic
/// iOS 26 Liquid Glass appearance.
///
/// **Usage:**
/// ```swift
/// GlassCard {
///     Text("Content")
/// }
/// ```
struct GlassCard<Content: View>: View {
    
    // MARK: - Properties
    
    let cornerRadius: CGFloat
    let padding: CGFloat
    let isInteractive: Bool
    @ViewBuilder let content: () -> Content
    
    // MARK: - Initialization
    
    init(
        cornerRadius: CGFloat = OGDesign.Radius.lg,
        padding: CGFloat = OGDesign.Spacing.md,
        isInteractive: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.isInteractive = isInteractive
        self.content = content
    }
    
    // MARK: - Body
    
    // MARK: - Body
    
    var body: some View {
        content()
            .padding(padding)
            .background {
                // Multi-layered background for depth
                ZStack {
                    // 1. Tint layer
                    OGDesign.Colors.glassFill
                    
                    // 2. Blur material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.thinMaterial) // Use thin for more substance
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8) // Deeper shadow
            }
            .overlay {
                // Premium glass border with gradient
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05),
                                .white.opacity(0.05),
                                .white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

// MARK: - Convenience Modifiers

extension View {
    
    /// Wrap content in a glass card
    func glassCard(
        cornerRadius: CGFloat = OGDesign.Radius.lg,
        padding: CGFloat = OGDesign.Spacing.md
    ) -> some View {
        GlassCard(cornerRadius: cornerRadius, padding: padding) {
            self
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OGDesign.Colors.meshGradient
            .ignoresSafeArea()
        
        VStack(spacing: OGDesign.Spacing.md) {
            GlassCard {
                VStack(alignment: .leading, spacing: OGDesign.Spacing.xs) {
                    Text("Balance")
                        .font(OGDesign.Typography.labelMedium)
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                    
                    Text("$12,450.00")
                        .font(OGDesign.Typography.displaySmall)
                        .foregroundStyle(OGDesign.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: OGDesign.Spacing.md) {
                GlassCard {
                    VStack(spacing: OGDesign.Spacing.xs) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                            .foregroundStyle(OGDesign.Colors.income)
                        
                        Text("Income")
                            .font(OGDesign.Typography.labelSmall)
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                        
                        Text("+$3,200")
                            .font(OGDesign.Typography.headlineSmall)
                            .foregroundStyle(OGDesign.Colors.income)
                    }
                }
                
                GlassCard {
                    VStack(spacing: OGDesign.Spacing.xs) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(OGDesign.Colors.expense)
                        
                        Text("Expense")
                            .font(OGDesign.Typography.labelSmall)
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                        
                        Text("-$1,840")
                            .font(OGDesign.Typography.headlineSmall)
                            .foregroundStyle(OGDesign.Colors.expense)
                    }
                }
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
