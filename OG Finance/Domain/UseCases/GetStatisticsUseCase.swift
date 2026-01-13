//
//  GetStatisticsUseCase.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

/// Protocol for computing financial statistics.
protocol GetStatisticsUseCaseProtocol: Sendable {
    
    /// Compute statistics for a given time period
    /// - Parameter period: The date interval to analyze
    /// - Returns: Computed statistics
    func execute(for period: DateInterval) async throws -> Statistics
    
    /// Compute statistics using a predefined period type
    /// - Parameter periodType: Week, month, quarter, year, or all time
    /// - Returns: Computed statistics
    func execute(for periodType: StatisticsPeriod) async throws -> Statistics
}

/// Concrete implementation of statistics computation.
///
/// **Off-main-thread computation:**
/// Statistics can involve many transactions. This use case
/// is designed to be called from a background context.
final class GetStatisticsUseCase: GetStatisticsUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let transactionRepository: any TransactionRepositoryProtocol
    private let categoryRepository: any CategoryRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        transactionRepository: any TransactionRepositoryProtocol,
        categoryRepository: any CategoryRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }
    
    // MARK: - Execution
    
    func execute(for periodType: StatisticsPeriod) async throws -> Statistics {
        let period = periodType.dateInterval()
        return try await execute(for: period)
    }
    
    func execute(for period: DateInterval) async throws -> Statistics {
        // Fetch transactions for period
        let transactions = try await transactionRepository.fetch(for: period)
        
        // Early return if no transactions
        guard !transactions.isEmpty else {
            return .empty(for: period)
        }
        
        // Fetch all categories for lookup
        let categories = try await categoryRepository.fetchAll()
        let categoryLookup = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        
        // Compute totals
        let incomeTransactions = transactions.filter { $0.type == .income }
        let expenseTransactions = transactions.filter { $0.type == .expense }
        
        let totalIncome = incomeTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        let totalExpenses = expenseTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        
        // Compute category breakdown
        let categoryBreakdown = computeCategoryBreakdown(
            transactions: transactions,
            categories: categoryLookup,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses
        )
        
        // Compute daily averages
        let daysInPeriod = Calendar.current.dateComponents([.day], from: period.start, to: period.end).day ?? 1
        let actualDays = max(daysInPeriod, 1)
        
        let dailyAverages = DailyAverages(
            averageIncome: totalIncome / Decimal(actualDays),
            averageExpense: totalExpenses / Decimal(actualDays),
            averageNetChange: (totalIncome - totalExpenses) / Decimal(actualDays),
            daysInPeriod: actualDays
        )
        
        return Statistics(
            period: period,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            transactionCount: transactions.count,
            categoryBreakdown: categoryBreakdown,
            dailyAverages: dailyAverages
        )
    }
    
    // MARK: - Private Helpers
    
    private func computeCategoryBreakdown(
        transactions: [Transaction],
        categories: [UUID: Category],
        totalIncome: Decimal,
        totalExpenses: Decimal
    ) -> [CategoryStatistic] {
        
        // Group transactions by category
        var categoryTotals: [UUID: (amount: Decimal, count: Int, type: TransactionType)] = [:]
        
        for transaction in transactions {
            let current = categoryTotals[transaction.categoryId] ?? (0, 0, transaction.type)
            categoryTotals[transaction.categoryId] = (
                current.amount + transaction.amount,
                current.count + 1,
                transaction.type
            )
        }
        
        // Convert to CategoryStatistic array
        var breakdown: [CategoryStatistic] = []
        
        for (categoryId, data) in categoryTotals {
            let category = categories[categoryId]
            let total = data.type == .income ? totalIncome : totalExpenses
            let percentage = total > 0 ? Double(truncating: (data.amount / total * 100) as NSNumber) : 0
            
            let stat = CategoryStatistic(
                id: categoryId,
                categoryName: category?.name ?? "Unknown",
                categoryIcon: category?.icon ?? "questionmark.circle",
                categoryColorHex: category?.colorHex ?? "808080",
                amount: data.amount,
                transactionCount: data.count,
                type: data.type,
                percentage: percentage
            )
            breakdown.append(stat)
        }
        
        // Sort by amount descending
        breakdown.sort { $0.amount > $1.amount }
        
        return breakdown
    }
}
