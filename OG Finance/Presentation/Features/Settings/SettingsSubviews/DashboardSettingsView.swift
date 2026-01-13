//
//  DashboardSettingsView.swift
//  OG Finance
//
//  Settings for customizing the dashboard appearance.
//

import SwiftUI

struct DashboardSettingsView: View {
    @AppStorage("dashboardStyle") var dashboardStyle: Int = 1
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            OGDesign.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: OGDesign.Spacing.lg) {
                    // Header
                    Text("Choose your preferred dashboard style")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, OGDesign.Spacing.md)
                    
                    // Dashboard Style Options
                    VStack(spacing: OGDesign.Spacing.md) {
                        DashboardStyleCard(
                            title: "Minimal",
                            description: "Clean and simple. Shows only essential information.",
                            icon: "square",
                            isSelected: dashboardStyle == 0
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                dashboardStyle = 0
                            }
                            HapticManager.shared.selection_()
                        }
                        
                        DashboardStyleCard(
                            title: "Standard",
                            description: "Balanced view with quick actions and recent transactions.",
                            icon: "square.grid.2x2",
                            isSelected: dashboardStyle == 1
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                dashboardStyle = 1
                            }
                            HapticManager.shared.selection_()
                        }
                        
                        DashboardStyleCard(
                            title: "Premium",
                            description: "Full-featured dashboard with insights and analytics preview.",
                            icon: "square.grid.3x3",
                            isSelected: dashboardStyle == 2
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                dashboardStyle = 2
                            }
                            HapticManager.shared.selection_()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Dashboard Style")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    SettingsBackButton()
                }
            }
        }
    }
}

// MARK: - Dashboard Style Card

struct DashboardStyleCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: OGDesign.Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? OGDesign.Colors.primary : OGDesign.Colors.glassFill)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? .white : OGDesign.Colors.textSecondary)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(OGDesign.Colors.textPrimary)
                    
                    Text(description)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(OGDesign.Colors.primary)
                }
            }
            .padding(OGDesign.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? OGDesign.Colors.primary.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Insights Settings View

struct InsightsSettingsView: View {
    @AppStorage("defaultChartType") var defaultChartType: Int = 2
    @AppStorage("animatedCharts") var animatedCharts: Bool = true
    @AppStorage("showCents") var showCents: Bool = true
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            OGDesign.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: OGDesign.Spacing.lg) {
                    // Default Chart Type
                    VStack(alignment: .leading, spacing: OGDesign.Spacing.sm) {
                        Text("DEFAULT TIME FRAME")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                            .tracking(1)
                        
                        HStack(spacing: OGDesign.Spacing.sm) {
                            ChartTypeButton(title: "Week", isSelected: defaultChartType == 1) {
                                defaultChartType = 1
                            }
                            ChartTypeButton(title: "Month", isSelected: defaultChartType == 2) {
                                defaultChartType = 2
                            }
                            ChartTypeButton(title: "Year", isSelected: defaultChartType == 3) {
                                defaultChartType = 3
                            }
                        }
                    }
                    .padding(OGDesign.Spacing.md)
                    .glassCard()
                    
                    // Toggle Settings
                    VStack(spacing: 0) {
                        SettingsToggleRow(
                            icon: "hare.fill",
                            title: "Animated Charts",
                            color: Color.cyan,
                            isOn: animatedCharts,
                            namespace: animation
                        ) {
                            animatedCharts.toggle()
                        }
                        
                        Divider()
                            .background(OGDesign.Colors.glassBorder)
                        
                        SettingsToggleRow(
                            icon: "centsign.circle.fill",
                            title: "Display Cents",
                            color: Color.orange,
                            isOn: showCents,
                            namespace: animation
                        ) {
                            showCents.toggle()
                        }
                    }
                    .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
                }
                .padding()
            }
        }
        .navigationTitle("Insights Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    SettingsBackButton()
                }
            }
        }
    }
}

struct ChartTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.selection_()
        }) {
            Text(title)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(isSelected ? .white : OGDesign.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, OGDesign.Spacing.sm)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(OGDesign.Colors.primary)
                    } else {
                        Capsule()
                            .fill(OGDesign.Colors.glassFill)
                            .overlay {
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                            }
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - First Day of Week Settings

struct FirstDayOfWeekSettingsView: View {
    @AppStorage("firstDayOfWeek") var firstDayOfWeek: Int = 1
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            OGDesign.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: OGDesign.Spacing.lg) {
                    Text("Choose the first day of your week for insights and statistics.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, OGDesign.Spacing.md)
                    
                    VStack(spacing: OGDesign.Spacing.sm) {
                        FirstDayOption(
                            day: "Sunday",
                            isSelected: firstDayOfWeek == 1
                        ) {
                            firstDayOfWeek = 1
                        }
                        
                        FirstDayOption(
                            day: "Monday",
                            isSelected: firstDayOfWeek == 2
                        ) {
                            firstDayOfWeek = 2
                        }
                        
                        FirstDayOption(
                            day: "Saturday",
                            isSelected: firstDayOfWeek == 7
                        ) {
                            firstDayOfWeek = 7
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("First Day of Week")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    SettingsBackButton()
                }
            }
        }
    }
}

struct FirstDayOption: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.selection_()
        }) {
            HStack {
                Text(day)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(OGDesign.Colors.primary)
                } else {
                    Circle()
                        .strokeBorder(OGDesign.Colors.textTertiary, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(OGDesign.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(OGDesign.Colors.primary.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        DashboardSettingsView()
    }
    .preferredColorScheme(.dark)
}
