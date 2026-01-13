//
//  MainTabView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

struct MainTabView: View {
    
    @State private var currentTab = "Log"
    @State private var addTransaction = false
    @State private var animate = false
    @State private var transactionCount = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch currentTab {
                case "Log":
                    DashboardView()
                case "Insights":
                    StatisticsView()
                case "Transactions":
                    NavigationStack {
                        TransactionListView()
                    }
                case "Settings":
                    SettingsView()
                default:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Tab Bar
            floatingTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $addTransaction) {
            AddTransactionView(
                transactionType: .expense,
                onSave: {
                    transactionCount += 1
                }
            )
        }
        .task {
            await checkTransactions()
        }
        .onChange(of: transactionCount) { _, newValue in
            withAnimation {
                animate = newValue == 0
            }
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
    
    // MARK: - Floating Tab Bar
    
    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house", tab: "Log")
            tabItem(icon: "chart.pie", tab: "Insights")
            
            // Plus Button
            centerPlusButton
            
            tabItem(icon: "list.bullet", tab: "Transactions")
            tabItem(icon: "gearshape", tab: "Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            ZStack {
                // Glass Background - thinMaterial for more visible blur
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.thinMaterial)
                
                // Subtle dark tint for better contrast
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.15))
                
                // Inner glow
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Tab Item
    
    private func tabItem(icon: String, tab: String) -> some View {
        let isSelected = currentTab == tab
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentTab = tab
            }
            HapticManager.shared.selection_()
        } label: {
            Image(systemName: isSelected ? "\(icon).fill" : icon)
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? OGDesign.Colors.primary : Color.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(TabBouncyStyle())
    }
    
    // MARK: - Center Plus Button
    
    private var centerPlusButton: some View {
        ZStack {
            // Pulse animation
            if animate {
                Circle()
                    .stroke(OGDesign.Colors.primary.opacity(0.5), lineWidth: 2)
                    .frame(width: 52, height: 52)
                    .scaleEffect(animate ? 1.4 : 1)
                    .opacity(animate ? 0 : 1)
            }
            
            Button {
                HapticManager.shared.medium()
                addTransaction = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        OGDesign.Colors.primary,
                                        OGDesign.Colors.primary.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: OGDesign.Colors.primary.opacity(0.4), radius: 12, y: 4)
            }
            .buttonStyle(PlusBouncyStyle())
        }
        .frame(width: 60)
    }
}

// MARK: - Button Styles

struct TabBouncyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PlusBouncyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
