//
//  DashboardViewModel.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation
import Observation

/// ViewModel for the Dashboard screen.
///
/// **Observation Framework:**
/// Using `@Observable` macro for efficient SwiftUI updates.
/// Only properties that change trigger view updates.
///
/// **Single Responsibility:**
/// This ViewModel only manages dashboard-related state and operations.
@MainActor
@Observable
final class DashboardViewModel {
    
    // MARK: - Dependencies
    
    private let transactionRepository: any TransactionRepositoryProtocol
    private let accountRepository: any AccountRepositoryProtocol
    private let categoryRepository: any CategoryRepositoryProtocol
    private let getStatisticsUseCase: any GetStatisticsUseCaseProtocol
    
    // MARK: - State
    
    var timeFrame: StatisticsPeriod = .month
    var totalBalance: Decimal = 0
    var periodIncome: Decimal = 0
    var periodExpenses: Decimal = 0
    var recentTransactions: [Transaction] = []
    var statistics: Statistics?
    var categoryBreakdown: [CategoryStatistic] = []
    var chartData: [ChartDataPoint] = []
    var selectedType: TransactionType = .expense
    var dailyAverage: Decimal = 0
    var percentageChange: Double = 0
    var lastPeriodNet: Decimal = 0
    
    var isLoading = false
    var error: Error?
    
    // MARK: - Computed
    
    var formattedBalance: String {
        totalBalance.formatted(currencyCode: "USD")
    }
    
    var formattedIncome: String {
        periodIncome.formatted(currencyCode: "USD")
    }
    
    var formattedExpenses: String {
        periodExpenses.formatted(currencyCode: "USD")
    }
    
    var periodNetChange: Decimal {
        periodIncome - periodExpenses
    }
    
    var isPositivePeriod: Bool {
        periodNetChange >= 0
    }
    
    // MARK: - Initialization
    
    init(
        transactionRepository: any TransactionRepositoryProtocol,
        accountRepository: any AccountRepositoryProtocol,
        categoryRepository: any CategoryRepositoryProtocol,
        getStatisticsUseCase: any GetStatisticsUseCaseProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
        self.getStatisticsUseCase = getStatisticsUseCase
    }
    
    /// Convenience initializer using DependencyContainer
    convenience init(container: DependencyContainer = .shared) {
        self.init(
            transactionRepository: container.transactionRepository,
            accountRepository: container.accountRepository,
            categoryRepository: container.categoryRepository,
            getStatisticsUseCase: container.makeGetStatisticsUseCase()
        )
    }
    
    // MARK: - Public Methods
    
    /// Change the current timeframe and reload data
    func changePeriod(_ period: StatisticsPeriod) async {
        guard timeFrame != period else { return }
        timeFrame = period
        await load()
    }
    
    /// Load all dashboard data
    func load() async {
        isLoading = true
        error = nil
        
        do {
            // Parallel loading for better performance
            async let balanceTask = accountRepository.totalBalance()
            async let transactionsTask = transactionRepository.fetchAll()
            async let statisticsTask = getStatisticsUseCase.execute(for: timeFrame)
            
            let (balance, transactions, stats) = try await (balanceTask, transactionsTask, statisticsTask)
            
            self.totalBalance = balance
            self.recentTransactions = Array(transactions.prefix(5))
            self.statistics = stats
            self.periodIncome = stats.totalIncome
            self.periodExpenses = stats.totalExpenses
            self.categoryBreakdown = stats.categoryBreakdown.filter { $0.type == .expense }
            self.dailyAverage = stats.dailyAverages.averageExpense
            
            // Calculate percentage change (mock for now)
            calculatePercentageChange(stats: stats)
            
            // Generate chart data
            generateChartData(transactions: transactions)
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Refresh data (called on pull-to-refresh or transaction changes)
    func refresh() async {
        await load()
    }
    
    // MARK: - Private Methods
    
    private func calculatePercentageChange(stats: Statistics) {
        // Calculate percentage change from last period
        let currentNet = Double(truncating: stats.totalIncome - stats.totalExpenses as NSNumber)
        let lastNet = Double(truncating: lastPeriodNet as NSNumber)
        
        if lastNet != 0 {
            percentageChange = ((currentNet - lastNet) / abs(lastNet)) * 100
        } else {
            percentageChange = currentNet > 0 ? 100 : (currentNet < 0 ? -100 : 0)
        }
    }
    
    private func generateChartData(transactions: [Transaction]) {
        let calendar = Calendar.current
        let today = Date()
        
        // Generate last 7 days
        var data: [ChartDataPoint] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
            
            let dayTransactions = transactions.filter { transaction in
                transaction.date >= dayStart && transaction.date < dayEnd && transaction.type == selectedType
            }
            
            let total = dayTransactions.reduce(Decimal.zero) { $0 + $1.amount }
            
            data.append(ChartDataPoint(
                label: String(dateFormatter.string(from: date).prefix(1)),
                value: Double(truncating: total as NSNumber),
                isCurrentPeriod: dayOffset <= 0
            ))
        }
        
        self.chartData = data
    }
}
