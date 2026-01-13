//
//  DebounceTask.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// A utility for debouncing async operations.
///
/// **Why debouncing is critical for keyboard input:**
/// - Each keystroke would otherwise trigger view updates
/// - Currency parsing is relatively expensive
/// - Network calls (if any) would be redundant
///
/// **Usage:**
/// ```swift
/// let debouncer = DebounceTask(delay: 0.1)
///
/// // In onChange:
/// await debouncer.submit {
///     await expensiveParsing()
/// }
/// ```
///
/// **How it works:**
/// When `submit` is called, any pending task is cancelled.
/// The new task waits for the delay before executing.
/// If another submit comes before delay expires, cycle repeats.
actor DebounceTask {
    
    // MARK: - Properties
    
    /// Delay in seconds before executing the debounced action
    private let delay: TimeInterval
    
    /// Currently pending task
    private var task: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Create a debounce task with specified delay
    /// - Parameter delay: Seconds to wait before executing (default: 0.1)
    init(delay: TimeInterval = 0.1) {
        self.delay = delay
    }
    
    // MARK: - Public Methods
    
    /// Submit an action to be executed after the debounce delay
    /// - Parameter action: The async action to execute
    func submit(action: @escaping @Sendable () async -> Void) {
        // Cancel any pending task
        task?.cancel()
        
        // Create new task with delay
        task = Task { [delay] in
            do {
                // Wait for debounce period
                try await Task.sleep(for: .seconds(delay))
                
                // Check if we were cancelled during sleep
                guard !Task.isCancelled else { return }
                
                // Execute the action
                await action()
            } catch {
                // Task was cancelled, which is expected behavior
            }
        }
    }
    
    /// Cancel any pending debounced action
    func cancel() {
        task?.cancel()
        task = nil
    }
}

// MARK: - Throttle Task

/// A utility for throttling operations (rate limiting).
///
/// Unlike debounce (which waits for quiet period),
/// throttle executes immediately but ignores subsequent
/// calls until the cooldown expires.
///
/// **Use case:**
/// Haptic feedback - we don't want to fire 100 haptics
/// if user types very fast.
actor ThrottleTask {
    
    // MARK: - Properties
    
    private let interval: TimeInterval
    private var lastExecutionTime: Date?
    
    // MARK: - Initialization
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    // MARK: - Public Methods
    
    /// Execute action if not within cooldown period
    /// - Parameter action: The action to potentially execute
    /// - Returns: Whether the action was executed
    @discardableResult
    func execute(action: @escaping @Sendable () async -> Void) async -> Bool {
        let now = Date()
        
        if let last = lastExecutionTime,
           now.timeIntervalSince(last) < interval {
            // Within cooldown, skip
            return false
        }
        
        lastExecutionTime = now
        await action()
        return true
    }
    
    /// Reset the throttle, allowing next call to execute immediately
    func reset() {
        lastExecutionTime = nil
    }
}
