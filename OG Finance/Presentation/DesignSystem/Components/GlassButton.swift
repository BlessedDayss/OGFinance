//
//  GlassButton.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

/// Button style for glass effect buttons.
///
/// **Features:**
/// - Press animation with scale
/// - Haptic feedback
/// - Glass material background
/// - Support for different sizes and styles
struct GlassButton: View {
    
    // MARK: - Types
    
    enum Style {
        case primary      // Gradient background
        case secondary    // Glass background
        case income       // Green gradient
        case expense      // Red gradient
        case destructive  // Red solid
        
        var background: AnyShapeStyle {
            switch self {
            case .primary:
                return AnyShapeStyle(OGDesign.Colors.primaryGradient)
            case .secondary:
                return AnyShapeStyle(.ultraThinMaterial)
            case .income:
                return AnyShapeStyle(OGDesign.Colors.incomeGradient)
            case .expense:
                return AnyShapeStyle(OGDesign.Colors.expenseGradient)
            case .destructive:
                return AnyShapeStyle(Color.red)
            }
        }
        
        var foregroundColor: Color {
            .white
        }
    }
    
    enum Size {
        case small
        case medium
        case large
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium:
                return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            case .large:
                return EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
            }
        }
        
        var font: Font {
            switch self {
            case .small:
                return OGDesign.Typography.labelSmall
            case .medium:
                return OGDesign.Typography.labelLarge
            case .large:
                return OGDesign.Typography.headlineSmall
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small:
                return OGDesign.Radius.xs
            case .medium:
                return OGDesign.Radius.sm
            case .large:
                return OGDesign.Radius.md
            }
        }
    }
    
    // MARK: - Properties
    
    let title: String
    let icon: String?
    let style: Style
    let size: Size
    let isFullWidth: Bool
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    // MARK: - Initialization
    
    init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        size: Size = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            HapticManager.shared.medium()
            action()
        } label: {
            HStack(spacing: OGDesign.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(style.foregroundColor)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(size.font)
                    }
                    
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                    // If this is a primary/action button, maybe bold/caps
                }
            }
            .foregroundStyle(style.foregroundColor)
            .padding(size.padding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background {
                Capsule() 
                    .fill(style.background)
                    .glassEffect(.regular, in: Capsule())
            }
            .shadow(
                color: style == .income ? OGDesign.Colors.income.opacity(0.3) :
                       style == .expense ? OGDesign.Colors.expense.opacity(0.3) :
                       style == .primary ? OGDesign.Colors.primary.opacity(0.3) :
                       Color.black.opacity(0.1),
                radius: 10, y: 5
            )
            .overlay {
                if style == .secondary {
                    Capsule()
                        .strokeBorder(OGDesign.Colors.glassBorder, lineWidth: 1)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Press Animation Style

struct PressableButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(OGDesign.Animation.springQuick, value: configuration.isPressed)
    }
}

// MARK: - Icon-only Button

struct GlassIconButton: View {
    
    let icon: String
    let size: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        icon: String,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button {
            HapticManager.shared.light()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(OGDesign.Colors.textPrimary)
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: Circle())
                }
                .overlay {
                    Circle()
                        .strokeBorder(OGDesign.Colors.glassBorder, lineWidth: 1)
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OGDesign.Colors.meshGradient
            .ignoresSafeArea()
        
        VStack(spacing: OGDesign.Spacing.lg) {
            GlassButton("Add Transaction", icon: "plus", style: .primary, size: .large, isFullWidth: true) {
                print("Tapped")
            }
            
            GlassButton("Income", icon: "arrow.down", style: .income, size: .medium) {
                print("Income")
            }
            
            GlassButton("Expense", icon: "arrow.up", style: .expense, size: .medium) {
                print("Expense")
            }
            
            GlassButton("Cancel", style: .secondary, size: .small) {
                print("Cancel")
            }
            
            HStack(spacing: OGDesign.Spacing.md) {
                GlassIconButton(icon: "gear") { }
                GlassIconButton(icon: "chart.bar") { }
                GlassIconButton(icon: "person") { }
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
