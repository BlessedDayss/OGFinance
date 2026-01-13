//
//  AppIntents.swift
//  NewOrioPlanner
//
//  App Intents for Shortcuts and Siri integration.
//

import AppIntents
import SwiftData

// MARK: - Add Expense Intent

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Quickly add a new expense")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Category")
    var category: String
    
    @Parameter(title: "Note")
    var note: String?
    
    func perform() async throws -> some IntentResult {
        // In production, this would add to the database
        return .result()
    }
}

// MARK: - View Budget Intent

struct ViewBudgetIntent: AppIntent {
    static var title: LocalizedStringResource = "View Budget"
    static var description = IntentDescription("Check your current budget status")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Get Spending Summary Intent

struct GetSpendingSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Spending Summary"
    static var description = IntentDescription("Get a summary of your spending")
    
    @Parameter(title: "Period", default: .month)
    var period: SpendingPeriod
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In production, fetch actual data
        return .result(value: "You've spent $1,250 this month")
    }
}

// MARK: - Spending Period Enum

enum SpendingPeriod: String, AppEnum {
    case day = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Spending Period"
    
    static var caseDisplayRepresentations: [SpendingPeriod: DisplayRepresentation] = [
        .day: "Today",
        .week: "This Week",
        .month: "This Month",
        .year: "This Year"
    ]
}

// MARK: - App Shortcuts Provider

struct NewOrioPlannerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Log expense with \(.applicationName)",
                "Record spending in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle.fill"
        )
        
        AppShortcut(
            intent: ViewBudgetIntent(),
            phrases: [
                "Check budget in \(.applicationName)",
                "View my budget with \(.applicationName)"
            ],
            shortTitle: "View Budget",
            systemImageName: "chart.pie.fill"
        )
        
        AppShortcut(
            intent: GetSpendingSummaryIntent(),
            phrases: [
                "How much have I spent in \(.applicationName)",
                "Get spending summary from \(.applicationName)"
            ],
            shortTitle: "Spending Summary",
            systemImageName: "chart.bar.fill"
        )
    }
}
