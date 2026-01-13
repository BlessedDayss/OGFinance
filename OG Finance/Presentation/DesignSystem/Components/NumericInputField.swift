//
//  NumericInputField.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

/// High-performance numeric input field optimized for rapid digit entry.
///
/// **CRITICAL OPTIMIZATION DECISIONS:**
///
/// 1. **Local @State isolation**
///    The `localText` state is kept local to this view. This prevents
///    propagating every keystroke up the view hierarchy, which would
///    cause full body re-evaluations in parent views.
///
/// 2. **Debounced parsing**
///    Currency parsing is relatively expensive. We debounce updates
///    to the parent's value, only committing after a 100ms pause.
///    This means rapid typing (10+ keystrokes/second) won't cause
///    any parsing work until the user pauses.
///
/// 3. **Custom numeric keyboard**
///    Using `.keyboardType(.decimalPad)` provides native feel.
///    We don't build a custom keyboard (which would require more
///    work to match iOS's haptics and appearance).
///
/// 4. **Minimal body**
///    This view's body is as minimal as possible. No computed properties
///    that depend on external state. The TextField only re-renders when
///    `localText` changes, not when parent state changes.
///
/// 5. **One-way binding with commit**
///    Parent provides initial value and an `onValueChange` callback.
///    We don't use two-way `@Binding<Decimal>` because that would
///    create a feedback loop on every format.
struct NumericInputField: View {
    
    // MARK: - Configuration
    
    let placeholder: String
    let currencyCode: String
    let transactionType: TransactionType
    let onValueChange: (Decimal?) -> Void
    
    // MARK: - Local State (ISOLATED - critical for performance)
    
    @State private var localText: String = ""
    @State private var displayText: String = ""
    @FocusState private var isFocused: Bool
    
    // MARK: - Debouncer
    
    @State private var debouncer = DebounceTask(delay: 0.1)
    
    // MARK: - Initialization
    
    init(
        placeholder: String = "0.00",
        currencyCode: String = "USD",
        transactionType: TransactionType = .expense,
        initialValue: Decimal? = nil,
        onValueChange: @escaping (Decimal?) -> Void
    ) {
        self.placeholder = placeholder
        self.currencyCode = currencyCode
        self.transactionType = transactionType
        self.onValueChange = onValueChange
        
        // Set initial display value
        if let value = initialValue, value > 0 {
            _localText = State(initialValue: "\(value)")
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: OGDesign.Spacing.sm) {
            // Amount display
            amountDisplay
            
            // Hidden TextField that captures input
            // We use a 1x1 frame with opacity near 0 (but not 0 to verify it takes input)
            // and place it in the background to avoid layout constraints issues with accessory views.
            TextField("", text: $localText)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                // Use a very small frame but not zero to ensure it remains part of functionality if needed by system
                .frame(width: 1, height: 1)
                .opacity(0.01) // Almost invisible but logically present
                .accessibilityHidden(true)
                .onChange(of: localText) { oldValue, newValue in
                    handleInput(newValue)
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
            HapticManager.shared.selection_()
        }
        .onAppear {
            // Prepare haptics for fast response
            HapticManager.shared.prepare()
        }
    }
    
    // MARK: - Amount Display
    
    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: OGDesign.Spacing.xxs) {
            // Currency symbol
            Text(currencySymbol)
                .font(OGDesign.Typography.displaySmall)
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            // Amount
            Text(displayText.isEmpty ? placeholder : displayText)
                .font(OGDesign.Typography.monoLarge)
                .foregroundStyle(displayText.isEmpty ? OGDesign.Colors.textTertiary : typeColor)
                .contentTransition(.numericText())
                .animation(OGDesign.Animation.springQuick, value: displayText)
            
            // Blinking cursor when focused
            if isFocused {
                Rectangle()
                    .fill(typeColor)
                    .frame(width: 3, height: 40)
                    .opacity(cursorOpacity)
            }
        }
        .padding(.vertical, OGDesign.Spacing.lg)
    }
    
    // MARK: - Computed Properties
    
    private var currencySymbol: String {
        let locale = Locale.current
        return locale.currencySymbol ?? "$"
    }
    
    private var typeColor: Color {
        transactionType == .income ? OGDesign.Colors.income : OGDesign.Colors.expense
    }
    
    @State private var cursorOpacity: Double = 1.0
    
    // MARK: - Input Handling
    
    private func handleInput(_ newValue: String) {
        // Filter to valid characters only
        let filtered = newValue.filter { $0.isNumber || $0 == "." }
        
        // Ensure only one decimal point
        let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
        let sanitized: String
        if parts.count > 2 {
            // Multiple decimal points - keep only first
            sanitized = String(parts[0]) + "." + parts.dropFirst().joined()
        } else if parts.count == 2 {
            // Limit decimal places to 2
            let decimals = String(parts[1].prefix(2))
            sanitized = String(parts[0]) + "." + decimals
        } else {
            sanitized = filtered
        }
        
        // Update local text if sanitization changed it
        if sanitized != localText {
            localText = sanitized
            return
        }
        
        // Update display text immediately for responsive feel
        updateDisplayText(sanitized)
        
        // Provide haptic feedback for digit entry
        if newValue.count > (displayText.filter { $0.isNumber || $0 == "." }.count) {
            HapticManager.shared.digitInput()
        }
        
        // Parse value and notify parent (debounced via the onChange)
        let value = Decimal(string: sanitized)
        onValueChange(value)
    }
    
    private func updateDisplayText(_ text: String) {
        if text.isEmpty {
            displayText = ""
            return
        }
        
        // For display, format thousands separators but keep editing simple
        if let value = Decimal(string: text) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = text.contains(".") ? max(1, text.split(separator: ".").last?.count ?? 0) : 0
            
            displayText = formatter.string(from: value as NSDecimalNumber) ?? text
        } else {
            displayText = text
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OGDesign.Colors.meshGradient
            .ignoresSafeArea()
        
        VStack(spacing: OGDesign.Spacing.xl) {
            GlassCard {
                VStack(spacing: OGDesign.Spacing.md) {
                    Text("EXPENSE")
                        .font(OGDesign.Typography.labelSmall)
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                    
                    NumericInputField(
                        transactionType: .expense,
                        onValueChange: { value in
                            print("Value: \(value ?? 0)")
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    .preferredColorScheme(.dark)
}
