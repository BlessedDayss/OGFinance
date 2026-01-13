//
//  TipJarView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 13/01/2026.
//

import SwiftUI

struct TipJarView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTip: TipOption? = nil
    @State private var showThankYou = false
    
    private let tips: [TipOption] = [
        TipOption(id: "small", emoji: "☕", title: "Coffee-Sized Tip", price: "$0.99"),
        TipOption(id: "medium", emoji: "🌮", title: "Taco-Sized Tip", price: "$2.99"),
        TipOption(id: "large", emoji: "🍕", title: "Pizza-Sized Tip", price: "$4.99"),
        TipOption(id: "xl", emoji: "🎂", title: "Cake-Sized Tip", price: "$9.99")
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            OGDesign.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: OGDesign.Spacing.lg) {
                // Header
                header
                
                if showThankYou {
                    thankYouView
                } else {
                    // Description
                    descriptionText
                    
                    // Tip Options
                    tipOptions
                    
                    // Footer
                    footerText
                }
                
                Spacer()
            }
            .padding(OGDesign.Spacing.lg)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(Color.pink)
            
            Text("Support OGTeam")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textPrimary)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .padding(8)
                    .background(OGDesign.Colors.glassFill, in: Circle())
            }
        }
    }
    
    // MARK: - Description
    
    private var descriptionText: some View {
        Text("OG Finance is built by a small indie team and is completely free with no ads or paywalls. If you enjoy using the app and want to support development, please consider leaving a tip!")
            .font(.system(.callout, design: .rounded).weight(.medium))
            .foregroundStyle(OGDesign.Colors.textSecondary)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - Tip Options
    
    private var tipOptions: some View {
        VStack(spacing: OGDesign.Spacing.sm) {
            ForEach(tips) { tip in
                tipRow(tip: tip)
            }
        }
        .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
    }
    
    @ViewBuilder
    private func tipRow(tip: TipOption) -> some View {
        HStack(spacing: OGDesign.Spacing.md) {
            Text(tip.emoji)
                .font(.title2)
            
            Text(tip.title)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textPrimary)
            
            Spacer()
            
            Button {
                selectTip(tip)
            } label: {
                Text(tip.price)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                    .padding(.horizontal, OGDesign.Spacing.md)
                    .padding(.vertical, OGDesign.Spacing.xs)
                    .background(OGDesign.Colors.glassFill, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, OGDesign.Spacing.xs)
    }
    
    // MARK: - Footer
    
    private var footerText: some View {
        Text("Have a great day ahead! 💜")
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundStyle(OGDesign.Colors.textTertiary)
    }
    
    // MARK: - Thank You View
    
    private var thankYouView: some View {
        VStack(spacing: OGDesign.Spacing.lg) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Thank You!")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(OGDesign.Colors.textPrimary)
            
            Text("Your support means the world to us. We'll keep working hard to make OG Finance even better!")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Text("— OGTeam 💜")
                .font(.system(.callout, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.primary)
            
            Spacer()
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Actions
    
    private func selectTip(_ tip: TipOption) {
        selectedTip = tip
        HapticManager.shared.success()
        
        // Simulate purchase (in real app, use StoreKit)
        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            showThankYou = true
        }
        
        // Auto dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dismiss()
        }
    }
}

// MARK: - Tip Option Model

struct TipOption: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let price: String
}

// MARK: - Preview

#Preview {
    TipJarView()
        .preferredColorScheme(.dark)
}
