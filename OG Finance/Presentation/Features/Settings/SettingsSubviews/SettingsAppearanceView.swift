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
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                }
            }
            .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
            
            // Note
            Text("Close and reopen app for changes to take effect.")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textTertiary)
                .padding(.horizontal, OGDesign.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            
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
