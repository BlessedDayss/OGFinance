//
//  SettingsHapticsView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 13/01/2026.
//

import SwiftUI

struct SettingsHapticsView: View {
    
    // MARK: - Properties
    
    @AppStorage("hapticType") var hapticType: Int = 1
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation
    
    private let options = [
        (0, "None", "speaker.slash.fill", "No haptic feedback"),
        (1, "Subtle", "waveform", "Light, pleasant feedback"),
        (2, "Excessive", "waveform.path.ecg", "Strong, prominent feedback")
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: OGDesign.Spacing.md) {
            // Header
            header
            
            // Options
            VStack(spacing: 0) {
                ForEach(options, id: \.0) { option in
                    hapticRow(
                        value: option.0,
                        title: option.1,
                        icon: option.2,
                        description: option.3,
                        isSelected: hapticType == option.0,
                        isLast: option.0 == options.last?.0
                    ) {
                        selectHaptic(option.0)
                    }
                }
            }
            .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
            
            // Preview button
            Button {
                previewHaptic()
            } label: {
                HStack(spacing: OGDesign.Spacing.sm) {
                    Image(systemName: "play.fill")
                    Text("Test Haptic")
                }
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, OGDesign.Spacing.lg)
                .padding(.vertical, OGDesign.Spacing.md)
                .background(OGDesign.Colors.primaryGradient, in: Capsule())
            }
            .padding(.top, OGDesign.Spacing.md)
            
            Spacer()
        }
        .modifier(SettingsSubviewModifier())
    }
    
    // MARK: - Header
    
    private var header: some View {
        Text("Haptics")
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
    
    // MARK: - Haptic Row
    
    @ViewBuilder
    private func hapticRow(
        value: Int,
        title: String,
        icon: String,
        description: String,
        isSelected: Bool,
        isLast: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: OGDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(OGDesign.Colors.textTertiary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.primary)
                    .matchedGeometryEffect(id: "hapticCheck", in: animation)
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
    
    // MARK: - Actions
    
    private func selectHaptic(_ value: Int) {
        withAnimation(.easeIn(duration: 0.15)) {
            hapticType = value
        }
        previewHaptic()
    }
    
    private func previewHaptic() {
        switch hapticType {
        case 0:
            // No haptic
            break
        case 1:
            // Subtle
            HapticManager.shared.light()
        case 2:
            // Excessive
            HapticManager.shared.heavy()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticManager.shared.medium()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                HapticManager.shared.light()
            }
        default:
            HapticManager.shared.light()
        }
    }
}

#Preview {
    SettingsHapticsView()
        .preferredColorScheme(.dark)
}
