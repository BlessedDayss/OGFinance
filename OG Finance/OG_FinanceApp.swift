//
//  OG_FinanceApp.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI
import SwiftData

/// Main app entry point.
///
/// **Architecture:**
/// - Initializes DependencyContainer for DI
/// - Seeds default data on first launch
/// - Sets up SwiftData model container
@main
struct OG_FinanceApp: App {
    
    // MARK: - Dependencies
    
    private let container = DependencyContainer.shared
    
    // MARK: - Appearance
    
    /// Color scheme setting: 0 = System, 1 = Light, 2 = Dark
    @AppStorage("colorScheme") private var colorSchemeSetting: Int = 0
    
    // MARK: - Computed
    
    private var preferredScheme: ColorScheme? {
        switch colorSchemeSetting {
        case 1: return .light
        case 2: return .dark
        default: return nil // System
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Configure appearance
        configureAppearance()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(preferredScheme)
                .modelContainer(container.modelContainer)
                .task {
                    await container.initializeDefaults()
                }
        }
    }
    
    // MARK: - Appearance Configuration
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithTransparentBackground()
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navigationAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        
        // Configure tab bar appearance (for fallback)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Hide default tab bar (we use custom)
        UITabBar.appearance().isHidden = true
    }
}
