//
//  MainTabView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

// MARK: - Tab Item Enum for stable identity
enum TabItem: String, CaseIterable, Identifiable {
    case log = "Log"
    case insights = "Insights"
    case transactions = "Transactions"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .log: return "house"
        case .insights: return "chart.pie"
        case .transactions: return "list.bullet"
        case .settings: return "gearshape"
        }
    }
    
    var filledIcon: String {
        switch self {
        case .log: return "house.fill"
        case .insights: return "chart.pie.fill"
        case .transactions: return "list.bullet"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    
    @State private var currentTab: TabItem = .log
    @State private var addTransaction = false
    @State private var animate = false
    @State private var transactionCount = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content - All views are always in memory but hidden
            // This prevents lag when switching tabs
            ZStack {
                DashboardView()
                    .opacity(currentTab == .log ? 1 : 0)
                    .zIndex(currentTab == .log ? 1 : 0)
                
                StatisticsView()
                    .opacity(currentTab == .insights ? 1 : 0)
                    .zIndex(currentTab == .insights ? 1 : 0)
                
                NavigationStack {
                    TransactionListView()
                }
                .opacity(currentTab == .transactions ? 1 : 0)
                .zIndex(currentTab == .transactions ? 1 : 0)
                
                SettingsView()
                    .opacity(currentTab == .settings ? 1 : 0)
                    .zIndex(currentTab == .settings ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Liquid Glass Floating Tab Bar
            liquidGlassTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $addTransaction) {
            AddTransactionView(
                onSave: {
                    transactionCount += 1
                }
            )
        }
        .task {
            await checkTransactions()
        }
        .onChange(of: transactionCount) { _, newValue in
            animate = newValue == 0
        }
    }
    
    private func checkTransactions() async {
        do {
            let transactions = try await DependencyContainer.shared.transactionRepository.fetchAll()
            transactionCount = transactions.count
            if transactions.isEmpty {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    // MARK: - Liquid Glass Tab Bar
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var liquidGlassTabBar: some View {
        HStack(spacing: 4) {
            // Left tabs
            tabButton(for: .log)
            tabButton(for: .insights)
            
            // Center Plus Button - rectangular style
            rectangularPlusButton
            
            // Right tabs
            tabButton(for: .transactions)
            tabButton(for: .settings)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            // Liquid Glass Background - Adaptive
            ZStack {
                // Layer 1: Ultra thin material for glass blur
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Layer 2: Subtle color overlay for depth
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.02)
                            ] : [
                                Color.black.opacity(0.03),
                                Color.black.opacity(0.01)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Layer 3: Glass highlight on top edge
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.08),
                                Color.clear
                            ] : [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                
                // Layer 4: Border glow
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.2)
                            ] : [
                                Color.black.opacity(0.08),
                                Color.black.opacity(0.04),
                                Color.black.opacity(0.02),
                                Color.black.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            // Outer shadow for floating effect
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.12), radius: 20, y: 10)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05), radius: 5, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Tab Button (Optimized)
    
    private func tabButton(for tab: TabItem) -> some View {
        Button {
            currentTab = tab
            HapticManager.shared.selection_()
        } label: {
            ZStack {
                Image(systemName: tab.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 24, maxHeight: 24)
                    .opacity(currentTab == tab ? 0 : 1)
                
                Image(systemName: tab.filledIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 24, maxHeight: 24)
                    .opacity(currentTab == tab ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .foregroundStyle(currentTab == tab ? OGDesign.Colors.textPrimary : OGDesign.Colors.textSecondary)
            .animation(.easeInOut(duration: 0.15), value: currentTab)
        }
        .buttonStyle(TabPressStyle())
    }
    
    // MARK: - Rectangular Plus Button
    
    private var rectangularPlusButton: some View {
        ZStack {
            // Outer pulse animation
            if animate {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(OGDesign.Colors.glassBorder)
                    .frame(width: 85, height: 58)
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1 : 0.5)
                
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(OGDesign.Colors.glassHighlight)
                    .frame(width: 70, height: 46)
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1 : 0.7)
            }
            
            Button {
                HapticManager.shared.light()
                addTransaction = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                    .frame(width: 56, height: 34)
                    .background {
                        // Glass button background - adaptive
                        ZStack {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(OGDesign.Colors.glassHighlight)
                            
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .strokeBorder(OGDesign.Colors.glassBorder, lineWidth: 0.5)
                        }
                    }
            }
            .buttonStyle(PlusRectangleStyle())
        }
        .frame(width: 70)
    }
}

// MARK: - Button Styles

struct TabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct PlusRectangleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}


// MARK: - Preview

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}

