//
//  SettingsView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI
import LocalAuthentication
import UserNotifications

struct SettingsView: View {
    
    // MARK: - App Storage
    
    @AppStorage("colorScheme") var colorScheme: Int = 0
    @AppStorage("currency") var currency: String = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("hapticType") var hapticType: Int = 1
    @AppStorage("showNotifications") var showNotifications: Bool = false
    @AppStorage("notificationOption") var notificationOption: Int = 1
    @AppStorage("incomeTracking") var incomeTracking: Bool = true
    @AppStorage("showCents") var showCents: Bool = true
    @AppStorage("animatedCharts") var animatedCharts: Bool = true
    @AppStorage("biometricEnabled") var biometricEnabled: Bool = false
    @AppStorage("dashboardStyle") var dashboardStyle: Int = 1  // 0: Minimal, 1: Standard, 2: Premium
    @AppStorage("firstDayOfWeek") var firstDayOfWeek: Int = 1  // 1: Sunday, 2: Monday
    @AppStorage("defaultChartType") var defaultChartType: Int = 2  // 1: Week, 2: Month, 3: Year
    
    // MARK: - State
    
    @State private var showTipJar = false
    @State private var showExportSheet = false
    @State private var showEraseConfirmation = false
    
    // MARK: - Environment
    
    @Environment(\.openURL) var openURL
    @Namespace private var animation
    
    // MARK: - Computed Properties
    
    private var colorSchemeString: String {
        switch colorScheme {
        case 1: return "Light"
        case 2: return "Dark"
        default: return "System"
        }
    }
    
    private var hapticString: String {
        switch hapticType {
        case 0: return "None"
        case 2: return "Excessive"
        default: return "Subtle"
        }
    }
    
    private var notificationString: String {
        guard showNotifications else { return "Off" }
        switch notificationOption {
        case 2: return "Evenings"
        case 3: return "Custom"
        default: return "Mornings"
        }
    }
    
    private var dashboardStyleString: String {
        switch dashboardStyle {
        case 0: return "Minimal"
        case 2: return "Premium"
        default: return "Standard"
        }
    }
    
    private var firstDayOfWeekString: String {
        switch firstDayOfWeek {
        case 2: return "Monday"
        default: return "Sunday"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AnimatedMeshBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: OGDesign.Spacing.lg) {
                        // Profile Header
                        profileHeader
                        
                        // GENERAL Section
                        settingsSection(title: "GENERAL") {
                            NavigationLink(destination: SettingsNotificationsView()) {
                                SettingsRowView(
                                    icon: "bell.fill",
                                    title: "Notifications",
                                    color: OGDesign.Colors.warning,
                                    optionalText: notificationString
                                )
                            }
                            
                            NavigationLink(destination: SettingsCurrencyView()) {
                                SettingsRowView(
                                    icon: "dollarsign.circle.fill",
                                    title: "Currency",
                                    color: OGDesign.Colors.income,
                                    optionalText: currency
                                )
                            }
                            
                            NavigationLink(destination: SettingsHapticsView()) {
                                SettingsRowView(
                                    icon: "hand.tap.fill",
                                    title: "Haptics",
                                    color: OGDesign.Colors.primary,
                                    optionalText: hapticString
                                )
                            }
                            
                            SettingsToggleRow(
                                icon: "faceid",
                                title: "Authentication",
                                color: Color.green,
                                isOn: biometricEnabled,
                                namespace: animation
                            ) {
                                toggleBiometric()
                            }
                            
                            SettingsToggleRow(
                                icon: "banknote.fill",
                                title: "Income Tracking",
                                color: OGDesign.Colors.income,
                                isOn: incomeTracking,
                                namespace: animation
                            ) {
                                incomeTracking.toggle()
                            }
                        }
                        
                        // APPEARANCE Section
                        settingsSection(title: "APPEARANCE") {
                            NavigationLink(destination: SettingsAppearanceView()) {
                                SettingsRowView(
                                    icon: "circle.righthalf.filled",
                                    title: "Theme",
                                    color: Color.purple,
                                    optionalText: colorSchemeString
                                )
                            }
                            
                            SettingsToggleRow(
                                icon: "centsign.circle.fill",
                                title: "Display Cents",
                                color: Color.orange,
                                isOn: showCents,
                                namespace: animation
                            ) {
                                showCents.toggle()
                            }
                            
                            SettingsToggleRow(
                                icon: "hare.fill",
                                title: "Animated Charts",
                                color: Color.cyan,
                                isOn: animatedCharts,
                                namespace: animation
                            ) {
                                animatedCharts.toggle()
                            }
                        }
                        
                        // DASHBOARD Section
                        settingsSection(title: "DASHBOARD") {
                            NavigationLink(destination: DashboardSettingsView()) {
                                SettingsRowView(
                                    icon: "square.grid.2x2.fill",
                                    title: "Dashboard Style",
                                    color: OGDesign.Colors.primary,
                                    optionalText: dashboardStyleString
                                )
                            }
                            
                            NavigationLink(destination: InsightsSettingsView()) {
                                SettingsRowView(
                                    icon: "chart.bar.fill",
                                    title: "Insights Settings",
                                    color: Color.indigo
                                )
                            }
                            
                            NavigationLink(destination: FirstDayOfWeekSettingsView()) {
                                SettingsRowView(
                                    icon: "calendar",
                                    title: "First Day of Week",
                                    color: Color.teal,
                                    optionalText: firstDayOfWeekString
                                )
                            }
                        }
                        
                        // DATA Section
                        settingsSection(title: "DATA") {
                            NavigationLink(destination: TransactionListView()) {
                                SettingsRowView(
                                    icon: "list.bullet.rectangle.fill",
                                    title: "All Transactions",
                                    color: Color.blue
                                )
                            }
                            
                            Button {
                                exportData()
                            } label: {
                                SettingsRowView(
                                    icon: "square.and.arrow.up.fill",
                                    title: "Export Data",
                                    color: Color.teal
                                )
                            }
                            
                            Button {
                                showEraseConfirmation = true
                            } label: {
                                SettingsRowView(
                                    icon: "xmark.bin.fill",
                                    title: "Erase All Data",
                                    color: OGDesign.Colors.expense
                                )
                            }
                        }
                        
                        // OTHERS Section
                        settingsSection(title: "OTHERS") {
                            Button {
                                showTipJar = true
                            } label: {
                                SettingsRowView(
                                    icon: "heart.fill",
                                    title: "Support OGTeam",
                                    color: Color.pink
                                )
                            }
                            
                            Button {
                                sendEmail(subject: "Bug Report - OG Finance")
                            } label: {
                                SettingsRowView(
                                    icon: "ladybug.fill",
                                    title: "Report Bug",
                                    color: OGDesign.Colors.expense
                                )
                            }
                            
                            Button {
                                sendEmail(subject: "Feature Request - OG Finance")
                            } label: {
                                SettingsRowView(
                                    icon: "hand.wave.fill",
                                    title: "Feature Request",
                                    color: Color.mint
                                )
                            }
                            
                            Button {
                                rateApp()
                            } label: {
                                SettingsRowView(
                                    icon: "star.fill",
                                    title: "Rate on App Store",
                                    color: Color.yellow
                                )
                            }
                            
                            Button {
                                shareApp()
                            } label: {
                                SettingsRowView(
                                    icon: "shareplay",
                                    title: "Share with Friends",
                                    color: OGDesign.Colors.primary
                                )
                            }
                            
                            Button {
                                openURL(URL(string: "https://x.com/OGTeam")!)
                            } label: {
                                SettingsRowView(
                                    icon: "bird.fill",
                                    title: "Follow OGTeam on X",
                                    color: Color.black
                                )
                            }
                        }
                        
                        // Footer
                        footerView
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showTipJar) {
            TipJarView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Erase All Data",
            isPresented: $showEraseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Erase Everything", role: .destructive) {
                eraseAllData()
            }
        } message: {
            Text("This will permanently delete all your transactions, categories, and accounts. This action cannot be undone.")
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        HStack(spacing: OGDesign.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [OGDesign.Colors.primary, OGDesign.Colors.primary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Text("OG")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("OG Finance")
                    .font(OGDesign.Typography.headlineMedium)
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                
                Text("Personal Finance Tracker")
                    .font(OGDesign.Typography.labelMedium)
                    .foregroundStyle(OGDesign.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(OGDesign.Spacing.lg)
        .glassCard()
    }
    
    // MARK: - Section Builder
    
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: OGDesign.Spacing.sm) {
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .padding(.horizontal, OGDesign.Spacing.xs)
                .tracking(1)
            
            VStack(spacing: 0) {
                content()
            }
            .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        VStack(spacing: OGDesign.Spacing.xs) {
            HStack(spacing: 4) {
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textTertiary)
            }
            
            Text("Made with ❤️ by OGTeam")
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary)
        }
        .padding(.top, OGDesign.Spacing.md)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Actions
    
    private func toggleBiometric() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if biometricEnabled {
                biometricEnabled = false
                HapticManager.shared.success()
            } else {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable biometric authentication") { success, _ in
                    DispatchQueue.main.async {
                        if success {
                            biometricEnabled = true
                            HapticManager.shared.success()
                        } else {
                            HapticManager.shared.error()
                        }
                    }
                }
            }
        } else {
            HapticManager.shared.error()
        }
    }
    
    private func exportData() {
        Task {
            let transactions = try? await DependencyContainer.shared.transactionRepository.fetchAll()
            
            guard let transactions = transactions, !transactions.isEmpty else {
                HapticManager.shared.warning()
                return
            }
            
            var csvText = "Date,Amount,Type,Note\n"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            for transaction in transactions {
                let type = transaction.type == .income ? "Income" : "Expense"
                let note = transaction.note.replacingOccurrences(of: ",", with: ";")
                csvText += "\(dateFormatter.string(from: transaction.date)),\(transaction.amount),\(type),\(note)\n"
            }
            
            let fileName = "OGFinance_Export_\(Date().formatted(.dateTime.year().month().day())).csv"
            let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try csvText.write(to: path, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: [path], applicationActivities: nil)
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }
                
                HapticManager.shared.success()
            } catch {
                HapticManager.shared.error()
            }
        }
    }
    
    private func eraseAllData() {
        Task {
            do {
                try await DependencyContainer.shared.transactionRepository.deleteAll()
                HapticManager.shared.success()
            } catch {
                HapticManager.shared.error()
            }
        }
    }
    
    private func sendEmail(subject: String) {
        let email = "ogteam@example.com"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)") {
            openURL(url)
        }
    }
    
    private func rateApp() {
        // Replace with actual App Store ID when available
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            openURL(url)
        }
    }
    
    private func shareApp() {
        let url = URL(string: "https://apps.apple.com/app/id123456789")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Settings Row View

struct SettingsRowView: View {
    let icon: String
    let title: String
    let color: Color
    var optionalText: String? = nil
    
    var body: some View {
        HStack(spacing: OGDesign.Spacing.md) {
            // Icon with colored background
            Image(systemName: icon)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            Text(title)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            if let text = optionalText {
                Text(text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(OGDesign.Colors.textTertiary)
                    .padding(.trailing, -4)
            }
            
            Image(systemName: "chevron.forward")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, OGDesign.Spacing.sm)
        .padding(.horizontal, OGDesign.Spacing.xs)
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let color: Color
    let isOn: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: OGDesign.Spacing.md) {
            // Icon with colored background
            Image(systemName: icon)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            Text(title)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            // Custom Toggle
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .frame(width: 44, height: 28)
                    .foregroundStyle(isOn ? Color.green : Color.gray.opacity(0.5))
                
                Circle()
                    .foregroundStyle(.white)
                    .padding(2)
                    .frame(width: 28, height: 28)
                    .matchedGeometryEffect(id: "toggle_\(title)", in: namespace)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onTap()
                }
                HapticManager.shared.light()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, OGDesign.Spacing.sm)
        .padding(.horizontal, OGDesign.Spacing.xs)
    }
}

// MARK: - Settings Back Button

struct SettingsBackButton: View {
    var body: some View {
        Image(systemName: "chevron.left")
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(OGDesign.Colors.textSecondary)
            .padding(8)
            .background(OGDesign.Colors.glassFill, in: Circle())
    }
}

// MARK: - Settings Subview Modifier

struct SettingsSubviewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .padding(OGDesign.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                AnimatedMeshBackground()
            }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
