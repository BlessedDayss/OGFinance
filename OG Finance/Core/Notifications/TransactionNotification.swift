//
//  TransactionNotification.swift
//  OG Finance
//
//  Notification system for real-time transaction updates.
//

import Foundation

/// Extension for Notification.Name to define custom notifications
extension Notification.Name {
    /// Posted when a transaction is added
    static let transactionAdded = Notification.Name("transactionAdded")
    
    /// Posted when a transaction is deleted
    static let transactionDeleted = Notification.Name("transactionDeleted")
    
    /// Posted when a transaction is updated
    static let transactionUpdated = Notification.Name("transactionUpdated")
    
    /// Posted when any transaction change occurs (add, delete, update)
    static let transactionsChanged = Notification.Name("transactionsChanged")
}

/// Transaction change info for optimistic UI updates
struct TransactionChangeInfo {
    let amount: Decimal
    let type: TransactionType
    let categoryId: UUID?
    let note: String?
}

/// Helper class to post transaction notifications
final class TransactionNotificationCenter {
    static let shared = TransactionNotificationCenter()
    
    private init() {}
    
    /// Post notification that a transaction was added with amount for instant UI update
    func postTransactionAdded(amount: Decimal, type: TransactionType) {
        let info = TransactionChangeInfo(amount: amount, type: type, categoryId: nil, note: nil)
        NotificationCenter.default.post(name: .transactionAdded, object: info)
        NotificationCenter.default.post(name: .transactionsChanged, object: info)
    }
    
    /// Post notification that a transaction was added (legacy)
    func postTransactionAdded(_ transaction: Transaction? = nil) {
        NotificationCenter.default.post(name: .transactionAdded, object: transaction)
        NotificationCenter.default.post(name: .transactionsChanged, object: nil)
    }
    
    /// Post notification that a transaction was deleted with amount for instant UI update
    func postTransactionDeleted(amount: Decimal, type: TransactionType) {
        let info = TransactionChangeInfo(amount: amount, type: type, categoryId: nil, note: nil)
        NotificationCenter.default.post(name: .transactionDeleted, object: info)
        NotificationCenter.default.post(name: .transactionsChanged, object: info)
    }
    
    /// Post notification that a transaction was deleted (legacy)
    func postTransactionDeleted(_ transaction: Transaction? = nil) {
        NotificationCenter.default.post(name: .transactionDeleted, object: transaction)
        NotificationCenter.default.post(name: .transactionsChanged, object: nil)
    }
    
    /// Post notification that a transaction was updated
    func postTransactionUpdated(_ transaction: Transaction? = nil) {
        NotificationCenter.default.post(name: .transactionUpdated, object: transaction)
        NotificationCenter.default.post(name: .transactionsChanged, object: nil)
    }
}
