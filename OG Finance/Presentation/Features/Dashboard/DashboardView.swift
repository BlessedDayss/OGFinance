//
//  DashboardView.swift
//  OG Finance
//
//

import SwiftUI

struct DashboardView: View {
    
    // MARK: - ViewModel
    
    @State private var viewModel = DashboardViewModel()
    
    // MARK: - State
    
    @State private var showAddTransaction = false
    @State private var selectedTransactionType: TransactionType = .expense
    @State private var hasAppeared = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            if viewModel.recentTransactions.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                mainContentView
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(
                transactionType: selectedTransactionType,
                onSave: {
                    Task { await viewModel.refresh() }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.load()
            withAnimation(.spring(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 5) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(OGDesign.Colors.textTertiary)
                .padding(.bottom, 20)
            
            Text("Your Log is Empty")
                .font(.system(.title2, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Text("Press the plus button\nto add your first entry")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 30)
        .frame(height: 250, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OGDesign.Colors.backgroundPrimary)
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar
                .padding(.horizontal, 25)
                .padding(.top, 10)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    LogInsightsSectionView(viewModel: viewModel)
                        .offset(y: hasAppeared ? 0 : 20)
                        .opacity(hasAppeared ? 1 : 0)
                    
                    // Quick Actions
                    quickActionsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        .offset(y: hasAppeared ? 0 : 20)
                        .opacity(hasAppeared ? 1 : 0)
                    
                    // Transactions List
                    transactionsListView
                        .padding(.horizontal, 20)
                        .offset(y: hasAppeared ? 0 : 20)
                        .opacity(hasAppeared ? 1 : 0)
                }
                .padding(.bottom, 100)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .background(OGDesign.Colors.backgroundPrimary)
        .navigationBarHidden(true)
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            Button {
                // Search action
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .padding(5)
            }
            
            Spacer()
            
            Text("OG Finance")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            Spacer()
            
            Button {
                // Filter action
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .padding(5)
            }
        }
        .frame(height: 50)
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        HStack(spacing: OGDesign.Spacing.sm) {
            // Add Income Button
            Button {
                selectedTransactionType = .income
                showAddTransaction = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Text("Income")
                        .font(.system(.body, design: .rounded).weight(.medium))
                }
                .foregroundStyle(OGDesign.Colors.income)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(OGDesign.Colors.income.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            }
            
            // Add Expense Button
            Button {
                selectedTransactionType = .expense
                showAddTransaction = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "minus")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Text("Expense")
                        .font(.system(.body, design: .rounded).weight(.medium))
                }
                .foregroundStyle(OGDesign.Colors.expense)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(OGDesign.Colors.expense.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Transactions List
    
    private var transactionsListView: some View {
        LazyVStack(spacing: 0) {
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                if let transactions = groupedTransactions[date] {
                    TransactionDaySection(
                        date: date,
                        transactions: transactions,
                        dayTotal: calculateDayTotal(transactions)
                    )
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: viewModel.recentTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
    }
    
    private func calculateDayTotal(_ transactions: [Transaction]) -> Decimal {
        transactions.reduce(Decimal.zero) { result, transaction in
            if transaction.type == .income {
                return result + transaction.amount
            } else {
                return result - transaction.amount
            }
        }
    }
}

struct LogInsightsSectionView: View {
    let viewModel: DashboardViewModel
    
    @State private var showPeriodMenu = false
    @State private var timeframe = 2 // 0: today, 1: week, 2: month, 3: year
    @State private var insightsType = 1 // 1: net, 2: income, 3: expense
    
    private let periodLabels = ["today", "this week", "this month", "this year"]
    
    private var headingText: String {
        switch insightsType {
        case 1: return "Net total"
        case 2: return "Earned"
        case 3: return "Spent"
        default: return "Net total"
        }
    }
    
    private var displayAmount: Decimal {
        switch insightsType {
        case 1: return viewModel.monthlyNetChange
        case 2: return viewModel.monthlyIncome
        case 3: return viewModel.monthlyExpenses
        default: return viewModel.monthlyNetChange
        }
    }
    
    var body: some View {
        VStack(spacing: -3) {
            VStack(spacing: 2) {
                // Heading with period selector
                HStack(spacing: 4) {
                    Text(headingText)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.9))
                    
                    Button {
                        showPeriodMenu = true
                    } label: {
                        Text(periodLabels[timeframe])
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.9))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .overlay {
                                Capsule()
                                    .strokeBorder(OGDesign.Colors.glassBorder, lineWidth: 1.3)
                            }
                    }
                }
                
                // Large Amount Display
                AmountDisplayView(
                    amount: displayAmount,
                    isNetTotal: insightsType == 1,
                    isPositive: viewModel.isPositiveMonth
                )
            }
            .padding(7)
            .contentShape(Rectangle())
            .onTapGesture {
                // Cycle through display types
                withAnimation(.easeInOut(duration: 0.2)) {
                    insightsType = insightsType == 3 ? 1 : insightsType + 1
                }
                HapticManager.shared.light()
            }
            
            // Income/Expense breakdown (only for net total)
            if viewModel.monthlyIncome != 0 && viewModel.monthlyExpenses != 0 && insightsType == 1 {
                HStack(spacing: 8) {
                    Text("+\(viewModel.monthlyIncome.formatted(currencyCode: "USD"))")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.income)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    // Dotted separator
                    DottedSeparator()
                        .frame(width: 2, height: 15)
                        .foregroundStyle(OGDesign.Colors.glassBorder)
                    
                    Text("-\(viewModel.monthlyExpenses.formatted(currencyCode: "USD"))")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.expense)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.bottom, 13)
            }
        }
        .padding([.bottom, .horizontal], 20)
        .frame(height: 170)
        .confirmationDialog("Select Period", isPresented: $showPeriodMenu) {
            ForEach(0..<4, id: \.self) { index in
                Button(periodLabels[index]) {
                    timeframe = index
                    HapticManager.shared.selection_()
                }
            }
        }
    }
}


struct AmountDisplayView: View {
    let amount: Decimal
    let isNetTotal: Bool
    let isPositive: Bool
    
    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }
    
    private var signedSymbol: String {
        if isNetTotal {
            return isPositive ? "+\(currencySymbol)" : "-\(currencySymbol)"
        }
        return currencySymbol
    }
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(signedSymbol)
                .font(.system(.largeTitle, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            Text(abs(amount).formatted(.number.precision(.fractionLength(0...2))))
                .font(.system(size: 50, weight: .regular, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textPrimary)
                .contentTransition(.numericText())
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

// MARK: - Dotted Separator

struct DottedSeparator: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.height))
        return path
    }
}


struct TransactionDaySection: View {
    let date: Date
    let transactions: [Transaction]
    let dayTotal: Decimal
    
    private var dateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, d MMM"
            return formatter.string(from: date).uppercased()
        }
    }
    
    private var totalString: String {
        let formatted = dayTotal.formatted(currencyCode: "USD", showPositiveSign: true)
        return formatted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Date Header
            VStack(spacing: 4) {
                HStack {
                    Text(dateText)
                    Spacer()
                    Text(totalString)
                        .layoutPriority(1)
                }
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                
                // Separator Line
                Rectangle()
                    .fill(OGDesign.Colors.glassBorder)
                    .frame(height: 1)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            // Transaction Rows
            ForEach(transactions) { transaction in
                OrioTransactionRow(transaction: transaction)
            }
        }
        .padding(.bottom, 18)
    }
}


struct OrioTransactionRow: View {
    let transaction: Transaction
    
    @State private var category: Category?
    @State private var offset: CGFloat = 0
    @GestureState private var isDragging = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: transaction.date)
    }
    
    private var amountString: String {
        let formatted = transaction.amount.formatted(currencyCode: "USD")
        return transaction.type == .income ? "+\(formatted)" : "-\(formatted)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Emoji Box
            EmojiCategoryBox(
                emoji: category?.icon ?? "💰",
                colorHex: category?.colorHex ?? "#7367F0"
            )
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? (category?.name ?? "Transaction") : transaction.note)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(timeString)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Amount
            Text(amountString)
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundStyle(transaction.type == .income ? OGDesign.Colors.income : OGDesign.Colors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .task {
            category = try? await DependencyContainer.shared.categoryRepository.fetch(byId: transaction.categoryId)
        }
    }
}

struct EmojiCategoryBox: View {
    let emoji: String
    let colorHex: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(hex: colorHex).opacity(0.73))
            
            Image(systemName: emoji)
                .font(.system(.title3))
                .foregroundStyle(.white)
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
