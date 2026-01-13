//
//  SettingsNotificationsView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 13/01/2026.
//

import SwiftUI
import UserNotifications

struct SettingsNotificationsView: View {
    
    // MARK: - Properties
    
    @AppStorage("showNotifications") var showNotifications: Bool = false
    @AppStorage("notificationOption") var notificationOption: Int = 1
    @AppStorage("customNotificationHour") var customHour: Int = 8
    @AppStorage("customNotificationMinute") var customMinute: Int = 0
    
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation
    
    @State private var customTime = Date()
    @State private var notificationsDenied = false
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: OGDesign.Spacing.md) {
            // Header
            header
            
            // Enable Toggle
            VStack(spacing: 0) {
                HStack {
                    Text("Enable Notifications")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Custom Toggle
                    ZStack(alignment: showNotifications ? .trailing : .leading) {
                        Capsule()
                            .frame(width: 44, height: 28)
                            .foregroundStyle(showNotifications ? Color.green : Color.gray.opacity(0.5))
                        
                        Circle()
                            .foregroundStyle(.white)
                            .padding(2)
                            .frame(width: 28, height: 28)
                            .matchedGeometryEffect(id: "notifToggle", in: animation)
                    }
                    .onTapGesture {
                        toggleNotifications()
                    }
                }
                .padding(.vertical, OGDesign.Spacing.sm)
                .padding(.horizontal, OGDesign.Spacing.xs)
            }
            .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
            
            // Time Options (only if notifications enabled)
            if showNotifications {
                VStack(spacing: 0) {
                    timeOption(
                        title: "Every morning (8:00 AM)",
                        isSelected: notificationOption == 1
                    ) {
                        selectOption(1)
                    }
                    
                    Divider().background(OGDesign.Colors.glassBorder)
                    
                    timeOption(
                        title: "Every evening (8:00 PM)",
                        isSelected: notificationOption == 2
                    ) {
                        selectOption(2)
                    }
                    
                    Divider().background(OGDesign.Colors.glassBorder)
                    
                    HStack {
                        Text("Custom Time")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(OGDesign.Colors.textPrimary)
                        
                        Spacer()
                        
                        if notificationOption == 3 {
                            DatePicker(
                                "",
                                selection: $customTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .tint(OGDesign.Colors.primary)
                            .onChange(of: customTime) { _, newValue in
                                updateCustomTime(newValue)
                            }
                        }
                        
                        if notificationOption == 3 {
                            Image(systemName: "checkmark")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(OGDesign.Colors.primary)
                                .matchedGeometryEffect(id: "timeCheck", in: animation)
                        }
                    }
                    .padding(.vertical, OGDesign.Spacing.sm)
                    .padding(.horizontal, OGDesign.Spacing.xs)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectOption(3)
                    }
                }
                .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Denied warning
            if notificationsDenied {
                HStack(spacing: OGDesign.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(OGDesign.Colors.warning)
                    
                    Text("Notifications are disabled. Please enable them in Settings.")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                }
                .padding(OGDesign.Spacing.md)
                .glassCard(cornerRadius: OGDesign.Radius.sm, padding: OGDesign.Spacing.sm)
                .onTapGesture {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            
            Spacer()
        }
        .modifier(SettingsSubviewModifier())
        .onAppear {
            loadCustomTime()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        Text("Notifications")
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
    
    // MARK: - Time Option Row
    
    @ViewBuilder
    private func timeOption(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textPrimary)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.primary)
                    .matchedGeometryEffect(id: "timeCheck", in: animation)
            }
        }
        .padding(.vertical, OGDesign.Spacing.sm)
        .padding(.horizontal, OGDesign.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
    
    // MARK: - Actions
    
    private func toggleNotifications() {
        if showNotifications {
            // Disable
            withAnimation(.easeInOut(duration: 0.2)) {
                center.removeAllPendingNotificationRequests()
                showNotifications = false
            }
            HapticManager.shared.light()
        } else {
            // Enable - check permissions first
            center.getNotificationSettings { settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        requestPermission()
                    case .denied:
                        notificationsDenied = true
                        HapticManager.shared.warning()
                    case .authorized, .provisional, .ephemeral:
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNotifications = true
                            scheduleNotification()
                        }
                        HapticManager.shared.success()
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
    
    private func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showNotifications = true
                        scheduleNotification()
                    }
                    HapticManager.shared.success()
                } else {
                    notificationsDenied = true
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    private func selectOption(_ option: Int) {
        withAnimation(.easeIn(duration: 0.15)) {
            notificationOption = option
        }
        HapticManager.shared.selection_()
        scheduleNotification()
    }
    
    private func loadCustomTime() {
        var components = DateComponents()
        components.hour = customHour
        components.minute = customMinute
        if let date = Calendar.current.date(from: components) {
            customTime = date
        }
    }
    
    private func updateCustomTime(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        customHour = components.hour ?? 8
        customMinute = components.minute ?? 0
        scheduleNotification()
    }
    
    private func scheduleNotification() {
        center.removeAllPendingNotificationRequests()
        
        guard showNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Track your spending!"
        content.body = "Don't forget to log your expenses today."
        content.sound = .default
        
        var components = DateComponents()
        
        switch notificationOption {
        case 1: // Morning
            components.hour = 8
            components.minute = 0
        case 2: // Evening
            components.hour = 20
            components.minute = 0
        case 3: // Custom
            components.hour = customHour
            components.minute = customMinute
        default:
            components.hour = 8
            components.minute = 0
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        center.add(request)
    }
}

#Preview {
    SettingsNotificationsView()
        .preferredColorScheme(.dark)
}
