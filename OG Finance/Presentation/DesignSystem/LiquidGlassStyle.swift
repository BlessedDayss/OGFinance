//
//  LiquidGlassStyle.swift
//  NewOrioPlanner
//
//  Liquid Glass UI design system for iOS 26+.
//

import SwiftUI

// MARK: - Design Tokens

enum LiquidGlass {
    
    // MARK: - Colors (Synced with OGDesign - Adaptive)
    
    enum Colors {
        // Primary (same for both modes)
        static let primary = Color(hex: "7367F0")
        static let secondary = Color(hex: "A8AAAE")
        
        // Semantic - Adaptive (from OGDesign)
        static let income = OGDesign.Colors.income
        static let expense = OGDesign.Colors.expense
        static let warning = Color(hex: "FF9F43")
        
        // Backgrounds - Adaptive
        static let backgroundPrimary = OGDesign.Colors.backgroundPrimary
        static let backgroundSecondary = OGDesign.Colors.backgroundSecondary
        static let backgroundTertiary = OGDesign.Colors.backgroundTertiary
        
        // Glass - Adaptive
        static let glassFill = OGDesign.Colors.glassFill
        static let glassBorder = OGDesign.Colors.glassBorder
        static let glassHighlight = OGDesign.Colors.glassHighlight
        
        // Text - Adaptive
        static let textPrimary = OGDesign.Colors.textPrimary
        static let textSecondary = OGDesign.Colors.textSecondary
        static let textTertiary = OGDesign.Colors.textTertiary
        
        // Gradients - Adaptive
        static let primaryGradient = LinearGradient(
            colors: [primary, Color(hex: "9F44D3")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let incomeGradient = OGDesign.Colors.incomeGradient
        
        static let expenseGradient = OGDesign.Colors.expenseGradient
        
        // Mesh Gradient - Adaptive
        static var meshGradient: MeshGradient {
            OGDesign.Colors.meshGradient
        }
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Radius
    
    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 28, weight: .bold, design: .rounded)
        
        static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 17, weight: .semibold, design: .rounded)
        
        static let bodyLarge = Font.system(size: 17, weight: .regular)
        static let bodyMedium = Font.system(size: 15, weight: .regular)
        static let bodySmall = Font.system(size: 13, weight: .regular)
        
        static let labelLarge = Font.system(size: 15, weight: .medium)
        static let labelMedium = Font.system(size: 13, weight: .medium)
        static let labelSmall = Font.system(size: 11, weight: .medium)
        
        static let monoLarge = Font.system(size: 48, weight: .bold, design: .monospaced)
        static let monoMedium = Font.system(size: 32, weight: .semibold, design: .monospaced)
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let springQuick = SwiftUI.Animation.spring(duration: 0.3, bounce: 0.2)
        static let springMedium = SwiftUI.Animation.spring(duration: 0.4, bounce: 0.25)
        static let springBouncy = SwiftUI.Animation.spring(duration: 0.5, bounce: 0.35)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background {
                // Multi-layered background for depth
                ZStack {
                    // 1. Tint layer
                    LiquidGlass.Colors.glassFill
                    
                    // 2. Blur material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.thinMaterial) // Use thin for more substance
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10) // Deeper shadow
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

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    let style: ButtonVariant
    
    enum ButtonVariant {
        case primary, secondary, income, expense
        
        var background: AnyShapeStyle {
            switch self {
            case .primary: return AnyShapeStyle(LiquidGlass.Colors.primaryGradient)
            case .secondary: return AnyShapeStyle(.ultraThinMaterial)
            case .income: return AnyShapeStyle(LiquidGlass.Colors.incomeGradient)
            case .expense: return AnyShapeStyle(LiquidGlass.Colors.expenseGradient)
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LiquidGlass.Typography.labelLarge)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, LiquidGlass.Spacing.lg)
            .padding(.vertical, LiquidGlass.Spacing.sm)
            .background {
                Capsule()
                    .fill(style.background)
                    .shadow(
                        color: style == .income ? LiquidGlass.Colors.income.opacity(0.3) :
                               style == .expense ? LiquidGlass.Colors.expense.opacity(0.3) :
                               style == .primary ? LiquidGlass.Colors.primary.opacity(0.3) :
                               .clear,
                        radius: 10, y: 5
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(LiquidGlass.Animation.springQuick, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    
    /// Apply glass card background
    func glassCard(cornerRadius: CGFloat = LiquidGlass.Radius.md) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply liquid glass background to entire view
    func liquidGlassBackground() -> some View {
        self.background {
            ZStack {
                LiquidGlass.Colors.backgroundPrimary
                LiquidGlass.Colors.meshGradient
                    .opacity(0.4) // Reduced opacity for subtlety
            }
            .ignoresSafeArea()
        }
    }
    
    /// Card shadow
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.2), radius: 16, y: 8)
    }
}

// Color.init(hex:) is defined in Core/Extensions/Color+Hex.swift

