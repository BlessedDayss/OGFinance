//
//  SettingsAppearanceView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 13/01/2026.
//

import SwiftUI

struct SettingsAppearanceView: View {
    
    // MARK: - Properties
    
    @AppStorage("colorScheme") var colorScheme: Int = 0
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation
    
    private let options = [
        ("System", "iphone"),
        ("Light", "sun.max.fill"),
        ("Dark", "moon.fill")
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: OGDesign.Spacing.md) {
            // Header
            header
            
            // Options
            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    optionRow(
                        title: option.0,
                        icon: option.1,
                        isSelected: colorScheme == index,
                        isLast: index == options.count - 1
                    ) {
                        withAnimation(.easeIn(duration: 0.15)) {
                            colorScheme = index
                        }
                        HapticManager.shared.selection_()
                    }
                }
            }
            .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
            
            // Preview
            previewSection
            
            Spacer()
        }
        .modifier(SettingsSubviewModifier())
    }
    
    // MARK: - Header
    
    private var header: some View {
        Text("Appearance")
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundStyle(OGDesign.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    dismiss()
                } label: {
                    SettingsBackButton()
                }
            }
            .padding(.bottom, OGDesign.Spacing.md)
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(spacing: OGDesign.Spacing.sm) {
            Text("Preview")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Preview cards
            HStack(spacing: OGDesign.Spacing.md) {
                // Light preview
                previewCard(isLight: true, isSelected: colorScheme == 1)
                
                // Dark preview
                previewCard(isLight: false, isSelected: colorScheme == 2)
            }
        }
        .padding(.top, OGDesign.Spacing.md)
    }
    
    @ViewBuilder
    private func previewCard(isLight: Bool, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isLight ? Color.white : Color(hex: "0F1520"))
                .frame(height: 60)
                .overlay {
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isLight ? Color.gray.opacity(0.2) : Color.white.opacity(0.1))
                            .frame(width: 50, height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isLight ? Color.gray.opacity(0.15) : Color.white.opacity(0.05))
                            .frame(width: 70, height: 6)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            isSelected ? OGDesign.Colors.primary : Color.clear,
                            lineWidth: 2
                        )
                }
            
            Text(isLight ? "Light" : "Dark")
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary)
        }
        .onTapGesture {
            withAnimation(.easeIn(duration: 0.15)) {
                colorScheme = isLight ? 1 : 2
            }
            HapticManager.shared.selection_()
        }
    }
    
    // MARK: - Option Row
    
    @ViewBuilder
    private func optionRow(
        title: String,
        icon: String,
        isSelected: Bool,
        isLast: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: OGDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textPrimary)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.primary)
                    .matchedGeometryEffect(id: "checkmark", in: animation)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, OGDesign.Spacing.sm)
        .padding(.horizontal, OGDesign.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .background(OGDesign.Colors.glassBorder)
            }
        }
    }
}

#Preview {
    SettingsAppearanceView()
        .preferredColorScheme(.dark)
}
