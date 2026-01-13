//
//  MainTabView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

/// Main tab navigation with glass effect tab bar.
struct MainTabView: View {
    
    // MARK: - State
    
    @State private var selectedTab: Tab = .dashboard
    @State private var showAddTransaction = false
    
    // MARK: - Tab Definition
    
    enum Tab: String, CaseIterable {
        case dashboard
        case transactions
        case statistics
        case settings
        
        var title: String {
            switch self {
            case .dashboard: return "Home"
            case .transactions: return "Transactions"
            case .statistics: return "Statistics"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .transactions: return "list.bullet"
            case .statistics: return "chart.pie.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(Tab.dashboard)
                
                NavigationStack {
                    TransactionListView()
                }
                .tag(Tab.transactions)
                
                StatisticsView()
                    .tag(Tab.statistics)
                
                SettingsView()
                    .tag(Tab.settings)
            }
            .tabViewStyle(.automatic)
            .ignoresSafeArea(edges: .bottom)
            
            // Custom glass tab bar
            customTabBar
        }
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, OGDesign.Spacing.md)
        .padding(.vertical, OGDesign.Spacing.sm)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: Capsule())
        }
        .overlay {
            Capsule()
                .strokeBorder(OGDesign.Colors.glassBorder, lineWidth: 1)
        }
        .padding(.horizontal, OGDesign.Spacing.lg)
        .padding(.bottom, OGDesign.Spacing.sm)
    }
    
    private func tabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(OGDesign.Animation.springQuick) {
                selectedTab = tab
            }
            HapticManager.shared.selection_()
        } label: {
            VStack(spacing: OGDesign.Spacing.xxs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolEffect(.bounce, value: selectedTab == tab)
                
                Text(tab.title)
                    .font(OGDesign.Typography.labelSmall)
            }
            .foregroundStyle(
                selectedTab == tab
                    ? OGDesign.Colors.primary
                    : OGDesign.Colors.textTertiary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, OGDesign.Spacing.xs)
            .background {
                if selectedTab == tab {
                    Capsule()
                        .fill(OGDesign.Colors.primary.opacity(0.15))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
