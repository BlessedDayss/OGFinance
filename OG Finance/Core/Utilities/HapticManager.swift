//
//  HapticManager.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import UIKit

/// Centralized haptic feedback manager.
///
/// **Single Responsibility Principle (SOLID-S)**:
/// This class has one job: provide haptic feedback.
///
/// **Why @MainActor?**
/// UIKit feedback generators must be called on main thread.
///
/// **Why singleton?**
/// Feedback generators are expensive to create. Reusing prepared
/// generators provides instant feedback with no latency.
@MainActor
final class HapticManager {
    
    // MARK: - Singleton
    
    static let shared = HapticManager()
    
    // MARK: - Feedback Generators
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    // MARK: - Initialization
    
    private init() {
        // Prepare generators for immediate feedback
        prepare()
    }
    
    // MARK: - Public Methods
    
    /// Prepare all generators for immediate response
    /// Call this when keyboard appears or before intensive input
    func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    /// Light impact - for subtle UI feedback
    /// Use for: digit entry, minor selections
    func light() {
        impactLight.impactOccurred()
        impactLight.prepare()
    }
    
    /// Medium impact - for confirmations
    /// Use for: button taps, toggle changes
    func medium() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }
    
    /// Heavy impact - for significant actions
    /// Use for: transaction saved, major state changes
    func heavy() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }
    
    /// Soft impact - for gentle feedback
    /// Use for: smooth transitions, subtle confirmations
    func soft() {
        impactSoft.impactOccurred()
        impactSoft.prepare()
    }
    
    /// Rigid impact - for firm feedback
    /// Use for: errors, hard stops
    func rigid() {
        impactRigid.impactOccurred()
        impactRigid.prepare()
    }
    
    /// Selection feedback - for picker changes
    /// Use for: category selection, date picker changes
    func selection_() {
        selection.selectionChanged()
        selection.prepare()
    }
    
    /// Success notification
    /// Use for: transaction saved successfully
    func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }
    
    /// Warning notification
    /// Use for: validation issues, low balance warnings
    func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }
    
    /// Error notification
    /// Use for: failed operations, invalid input
    func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }
    
    /// Custom impact with intensity
    /// - Parameter intensity: Value from 0.0 to 1.0
    func impact(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
}

// MARK: - Convenience Extensions

extension HapticManager {
    
    /// Feedback for numeric input (very light)
    func digitInput() {
        impactSoft.impactOccurred(intensity: 0.5)
        impactSoft.prepare()
    }
    
    /// Feedback for backspace
    func backspace() {
        impactLight.impactOccurred(intensity: 0.7)
        impactLight.prepare()
    }
    
    /// Feedback for transaction type toggle
    func transactionTypeToggle() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }
    
    /// Feedback for amount cleared
    func amountCleared() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }
}
