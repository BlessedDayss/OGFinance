//
//  DesignTokens.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

/// Design tokens for the OG Finance app.
///
/// **Purpose:**
/// Centralized design system for consistent UI across the app.
/// All colors, spacing, typography, and other values are defined here.
/// Supports both Light and Dark modes.
enum OGDesign {
    
    // MARK: - Colors (Adaptive for Light/Dark mode)
    
    enum Colors {
        static let primary = Color(hex: "7367F0")
        static let secondary = Color(hex: "A8AAAE")
        
        // Semantic colors - Adaptive (like appDIME)
        static let income = Color("IncomeGreen")
        static let expense = Color("ExpenseRed")
        static let warning = Color(hex: "FF9F43") // Orange
        
        // Background colors - Adaptive
        static let backgroundPrimary = Color("BackgroundPrimary")
        static let backgroundSecondary = Color("BackgroundSecondary")
        static let backgroundTertiary = Color("BackgroundTertiary")
        
        // Glass effect colors - Adaptive
        static let glassFill = Color("GlassFill")
        static let glassBorder = Color("GlassBorder")
        static let glassHighlight = Color("GlassHighlight")
        
        // Text colors - Adaptive
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let textTertiary = Color("TextTertiary")
        
        // Gradients - use adaptive colors
        static let incomeGradient = LinearGradient(
            colors: [income, income.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let expenseGradient = LinearGradient(
            colors: [expense, expense.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "7367F0"), Color(hex: "9F44D3")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Mesh Gradient - uses adaptive colors
        static var meshGradient: MeshGradient {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    backgroundPrimary, backgroundSecondary, backgroundTertiary,
                    backgroundSecondary, backgroundTertiary, backgroundSecondary,
                    backgroundTertiary, backgroundSecondary, backgroundPrimary
                ]
            )
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
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let full: CGFloat = 9999
    }
    
    // MARK: - Typography
    
    enum Typography {
        // Display
        static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 28, weight: .bold, design: .rounded)
        
        // Headlines
        static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 17, weight: .semibold, design: .rounded)
        
        // Body
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
        
        // Labels
        static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        
        // Mono (for numbers)
        static let monoLarge = Font.system(size: 48, weight: .bold, design: .monospaced)
        static let monoMedium = Font.system(size: 32, weight: .semibold, design: .monospaced)
        static let monoSmall = Font.system(size: 20, weight: .medium, design: .monospaced)
    }
    
    // MARK: - Animation
    
    enum Animation {
        // Spring animations optimized for 120Hz ProMotion
        static let springQuick = SwiftUI.Animation.spring(duration: 0.3, bounce: 0.2)
        static let springMedium = SwiftUI.Animation.spring(duration: 0.4, bounce: 0.25)
        static let springBouncy = SwiftUI.Animation.spring(duration: 0.5, bounce: 0.35)
        
        // Smooth easing
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        // Interactive
        static let interactiveSpring = SwiftUI.Animation.interactiveSpring(
            response: 0.3,
            dampingFraction: 0.7,
            blendDuration: 0.1
        )
    }
    
    // MARK: - Shadows
    
    enum Shadows {
        static let small = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let medium = (color: Color.black.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let large = (color: Color.black.opacity(0.25), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
        
        // Glow effects for income/expense
        static let incomeGlow = (color: Color(hex: "28C76F").opacity(0.4), radius: CGFloat(20))
        static let expenseGlow = (color: Color(hex: "EA5455").opacity(0.4), radius: CGFloat(20))
    }
}

// MARK: - View Extensions

extension View {
    
    /// Apply standard OG Design card shadow
    func ogCardShadow() -> some View {
        self.shadow(
            color: OGDesign.Shadows.medium.color,
            radius: OGDesign.Shadows.medium.radius,
            x: OGDesign.Shadows.medium.x,
            y: OGDesign.Shadows.medium.y
        )
    }
    
    /// Apply income glow effect
    func incomeGlow() -> some View {
        self.shadow(
            color: OGDesign.Shadows.incomeGlow.color,
            radius: OGDesign.Shadows.incomeGlow.radius
        )
    }
    
    /// Apply expense glow effect
    func expenseGlow() -> some View {
        self.shadow(
            color: OGDesign.Shadows.expenseGlow.color,
            radius: OGDesign.Shadows.expenseGlow.radius
        )
    }
}
