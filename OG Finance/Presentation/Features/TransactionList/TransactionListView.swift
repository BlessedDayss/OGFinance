//
//  TransactionListView.swift
//  OG Finance
//
//  Created by OGTeam on 07/01/2026.
//

import SwiftUI

struct TransactionListView: View {
    
    @State private var transactions: [Transaction] = []
    @State private var categories: [Category] = []
    @State private var isLoading = true
    
    // Currency
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    
    // Search
    @State private var searchMode = false
    
    // Filter
    @State private var showFilter = false
    @State private var filterType: LogFilterType = .all
    @State private var categoryFilter: Category?
    @State private var incomeFilter = false
    
    // Insights
    @State private var insightsTimeframe = 2 // 0: today, 1: week, 2: month, 3: year, 4: all
    @State private var insightsType = 1 // 1: net, 2: income, 3: expense
    @State private var showTimeframePicker = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var filteredTransactions: [Transaction] {
        var result = transactions
        
        switch filterType {
        case .all:
            break
        case .category:
            if let cat = categoryFilter {
                result = result.filter { $0.categoryId == cat.id }
            }
        case .type:
            result = result.filter { ($0.type == .income) == incomeFilter }
        case .recurring:
            // Filter recurring transactions if needed
            break
        }
        
        return result
    }
    
    private var groupedTransactions: [(Date, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    // MARK: - Insights Calculations
    
    private var insightsDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date.now
        
        switch insightsTimeframe {
        case 0: // Today
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case 1: // Week
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            return (weekStart, now)
        case 2: // Month
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            return (monthStart, now)
        case 3: // Year
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            return (yearStart, now)
        default: // All time
            return (Date.distantPast, now)
        }
    }
    
    private var insightsTransactions: [Transaction] {
        let range = insightsDateRange
        return transactions.filter { $0.date >= range.start && $0.date <= range.end }
    }
    
    private var totalIncome: Decimal {
        insightsTransactions.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var totalExpense: Decimal {
        insightsTransactions.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var netTotal: Decimal {
        totalIncome - totalExpense
    }
    
    private var displayedAmount: Decimal {
        switch insightsType {
        case 1: return netTotal
        case 2: return totalIncome
        default: return totalExpense
        }
    }
    
    private var insightsHeading: String {
        switch insightsType {
        case 1: return "Net total"
        case 2: return "Earned"
        default: return "Spent"
        }
    }
    
    private let timeframeOptions = ["today", "this week", "this month", "this year", "all time"]
    
    var body: some View {
        if transactions.isEmpty && !isLoading {
            emptyStateView
        } else {
            mainContentView
        }
    }
    
    // MARK: - Empty State
    
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
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Header with search and filter
            headerBar
                .padding(.horizontal, 25)
                .padding(.top, 10)
            
            // Filter stepper views
            filterStepperView
                .padding(.horizontal, 25)
                .padding(.top, filterType == .all ? 0 : 18)
                .frame(height: filterType == .all ? 0 : 50)
            
            ScrollView(showsIndicators: false) {
                // Insights Section (only when filter is .all)
                if filterType == .all {
                    insightsSection
                        .padding(.top, 10)
                }
                
                // Transactions List
                LazyVStack(spacing: 0) {
                    ForEach(groupedTransactions, id: \.0) { date, dayTransactions in
                        LogDaySectionView(
                            date: date,
                            transactions: dayTransactions,
                            categories: categories,
                            onDelete: { transaction in
                                deleteTransaction(transaction)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .refreshable {
                await loadData()
            }
        }
        .background(OGDesign.Colors.backgroundPrimary)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $searchMode) {
            LogSearchView(transactions: transactions, categories: categories)
        }
        .task {
            await loadData()
        }
        .onAppear {
            // Reload data when view appears (e.g., after dismissing add transaction sheet)
            Task {
                await loadData()
            }
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            // Search Button
            Button {
                searchMode = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(.title2, design: .rounded).weight(.regular))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .padding(5)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            // Filter Tag
            if filterType != .all {
                filterTagView
            }
            
            Spacer()
            
            // Filter Button
            Menu {
                ForEach(LogFilterType.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeIn(duration: 0.15)) {
                            filterType = filter
                        }
                        HapticManager.shared.selection_()
                    } label: {
                        Label(filter.title, systemImage: filterType == filter ? "checkmark" : filter.icon)
                    }
                }
            } label: {
                Image(systemName: filterType == .all ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                    .font(.system(.title2, design: .rounded).weight(.regular))
                    .foregroundStyle(filterType == .all ? OGDesign.Colors.textSecondary : OGDesign.Colors.primary)
                    .rotationEffect(.degrees(180))
                    .padding(5)
                    .contentShape(Rectangle())
            }
        }
        .frame(height: 50)
    }
    
    // MARK: - Filter Tag
    
    private var filterTagView: some View {
        HStack(spacing: 10) {
            Text(filterType.title)
                .font(.system(.body, design: .rounded).weight(.medium))
            
            Button {
                withAnimation(.easeIn(duration: 0.15)) {
                    filterType = .all
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.7))
            }
        }
        .padding(4)
        .padding(.horizontal, 6)
        .background(OGDesign.Colors.glassFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .foregroundStyle(OGDesign.Colors.textPrimary)
    }
    
    // MARK: - Filter Stepper Views
    
    @ViewBuilder
    private var filterStepperView: some View {
        switch filterType {
        case .all:
            EmptyView()
        case .category:
            LogCategoryStepperView(
                categoryFilter: $categoryFilter,
                categories: categories
            )
        case .type:
            LogIncomeToggleView(income: $incomeFilter)
        case .recurring:
            EmptyView()
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(spacing: -3) {
            VStack(spacing: 2) {
                // Heading with timeframe picker
                HStack(spacing: 4) {
                    Text(insightsHeading)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.9))
                    
                    Menu {
                        ForEach(0..<timeframeOptions.count, id: \.self) { index in
                            Button {
                                insightsTimeframe = index
                            } label: {
                                HStack {
                                    Text(timeframeOptions[index])
                                    if insightsTimeframe == index {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(timeframeOptions[insightsTimeframe])
                            .padding(2)
                            .padding(.horizontal, 6)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.9))
                            .overlay(Capsule().stroke(OGDesign.Colors.glassBorder, lineWidth: 1.3))
                    }
                }
                
                // Amount Display
                LogAmountView(
                    amount: displayedAmount,
                    isNetTotal: insightsType == 1,
                    isPositive: netTotal >= 0
                )
            }
            .padding(7)
            .contentShape(Rectangle())
            .onTapGesture {
                // Cycle through insights types
                insightsType = insightsType == 3 ? 1 : insightsType + 1
                HapticManager.shared.selection_()
            }
            
            // Income/Expense breakdown (only for net total)
            if insightsType == 1 && totalExpense > 0 && totalIncome > 0 {
                HStack {
                    Text("+\(totalIncome.formatted(currencyCode: currency))")
                        .font(.system(.title2, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.income)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    LogDottedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
                        .frame(width: 1.7, height: 15)
                        .foregroundStyle(OGDesign.Colors.glassBorder)
                    
                    Text("-\(totalExpense.formatted(currencyCode: currency))")
                        .font(.system(.title2, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.expense)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.bottom, 13)
            }
        }
        .padding([.bottom, .horizontal], 20)
        .frame(height: 170)
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        isLoading = true
        
        do {
            async let transactionsTask = DependencyContainer.shared.transactionRepository.fetchAll()
            async let categoriesTask = DependencyContainer.shared.categoryRepository.fetchAll()
            
            let (fetchedTransactions, fetchedCategories) = try await (transactionsTask, categoriesTask)
            
            transactions = fetchedTransactions
            categories = fetchedCategories
            
            print("📋 TransactionListView loaded: \(transactions.count) transactions, \(categories.count) categories")
            
            // Set initial category filter if needed
            if categoryFilter == nil && !categories.isEmpty {
                categoryFilter = categories.first(where: { $0.applicableTypes.contains(.expense) })
            }
        } catch {
            print("❌ Error loading data: \(error)")
        }
        
        isLoading = false
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        Task {
            do {
                try await DependencyContainer.shared.makeDeleteTransactionUseCase().execute(id: transaction.id)
                transactions.removeAll { $0.id == transaction.id }
                HapticManager.shared.success()
            } catch {
                HapticManager.shared.error()
            }
        }
    }
}

// MARK: - Filter Type Enum

enum LogFilterType: String, CaseIterable {
    case all = "All"
    case category = "Category"
    case type = "Type"
    case recurring = "Recurring"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .category: return "square.grid.2x2"
        case .type: return "arrow.left.arrow.right"
        case .recurring: return "repeat"
        }
    }
}

// MARK: - Log Amount View

struct LogAmountView: View {
    let amount: Decimal
    let isNetTotal: Bool
    let isPositive: Bool
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    
    private var currencySymbol: String {
        CurrencyManager.symbol(for: currency)
    }
    
    private var prefix: String {
        guard isNetTotal else { return currencySymbol }
        return isPositive ? "+\(currencySymbol)" : "-\(currencySymbol)"
    }
    
    private var displayAmount: Decimal {
        abs(amount)
    }
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(prefix)
                .font(.system(.largeTitle, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            Text(displayAmount.formatted(.number.precision(.fractionLength(0...2))))
                .font(.system(size: 50, weight: .regular, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textPrimary)
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

// MARK: - Dotted Line

struct LogDottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - Day Section View

struct LogDaySectionView: View {
    let date: Date
    let transactions: [Transaction]
    let categories: [Category]
    let onDelete: (Transaction) -> Void
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    
    private var dateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "TODAY")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "YESTERDAY")
        } else {
            let formatter = DateFormatter()
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: Date.now)) ?? Date.now
            
            if date < yearStart {
                formatter.dateFormat = "EEE, d MMM yy"
            } else {
                formatter.dateFormat = "EEE, d MMM"
            }
            return formatter.string(from: date).uppercased()
        }
    }
    
    private var dayTotal: Decimal {
        transactions.reduce(Decimal.zero) { result, transaction in
            if transaction.type == .income {
                return result + transaction.amount
            } else {
                return result - transaction.amount
            }
        }
    }
    
    private var totalString: String {
        dayTotal.formatted(currencyCode: currency, showPositiveSign: true)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                HStack {
                    Text(dateText)
                    Spacer()
                    Text(totalString)
                        .layoutPriority(1)
                }
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                
                LogLine()
                    .stroke(OGDesign.Colors.glassBorder, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            // Transaction Rows
            ForEach(transactions) { transaction in
                LogTransactionRowView(
                    transaction: transaction,
                    category: categories.first(where: { $0.id == transaction.categoryId }),
                    onDelete: { onDelete(transaction) }
                )
            }
        }
        .padding(.bottom, 18)
    }
}

// MARK: - Line Shape

struct LogLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Transaction Row View

struct LogTransactionRowView: View {
    let transaction: Transaction
    let category: Category?
    let onDelete: () -> Void
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    @State private var offset: CGFloat = 0
    @State private var deleted: Bool = false
    @GestureState private var isDragging = false
    
    private var deletePopup: Bool {
        abs(offset) > UIScreen.main.bounds.width * 0.2
    }
    
    private var deleteConfirm: Bool {
        abs(offset) > UIScreen.main.bounds.width * 0.42
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: transaction.date)
    }
    
    private var amountString: String {
        let formatted = transaction.amount.formatted(currencyCode: currency)
        return transaction.type == .income ? "+\(formatted)" : "-\(formatted)"
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete indicator
            Image(systemName: "xmark")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(deleteConfirm ? OGDesign.Colors.expense : OGDesign.Colors.textSecondary)
                .padding(5)
                .background(
                    deleteConfirm ? OGDesign.Colors.expense.opacity(0.23) : OGDesign.Colors.glassFill,
                    in: Circle()
                )
                .scaleEffect(deleteConfirm ? 1.1 : 1)
                .opacity(deleted ? 0 : 1)
                .padding(.horizontal, 10)
                .offset(x: 80)
                .offset(x: max(-80, offset))
            
            // Main Content
            HStack(spacing: 12) {
                // Category Emoji Box
                LogEmojiView(
                    emoji: category?.icon ?? "💰",
                    color: category?.colorHex ?? "#7367F0"
                )
                
                // Note and Time
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
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .offset(x: offset)
        }
        .onChange(of: deletePopup) { _, newValue in
            if newValue {
                HapticManager.shared.light()
            }
        }
        .onChange(of: deleteConfirm) { _, newValue in
            if newValue {
                HapticManager.shared.medium()
            }
        }
        .animation(.easeInOut, value: deletePopup)
        .simultaneousGesture(
            DragGesture()
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    if value.translation.width < 0 {
                        withAnimation {
                            offset = value.translation.width
                        }
                    }
                }
                .onEnded { _ in
                    if deleteConfirm {
                        deleted = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset -= UIScreen.main.bounds.width
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onDelete()
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
        .onChange(of: isDragging) { _, newValue in
            if !newValue && !deleted {
                withAnimation(.easeInOut(duration: 0.3)) {
                    offset = 0
                }
            }
        }
    }
}

// MARK: - Emoji View

struct LogEmojiView: View {
    let emoji: String
    let color: String
    
    // Known SF Symbols without dots
    private let sfSymbolsWithoutDots = [
        "laptopcomputer", "desktopcomputer", "macbook", "iphone", "ipad",
        "airpods", "homepod", "applewatch", "appletv", "airplane",
        "car", "bus", "tram", "bicycle", "scooter", "figure"
    ]
    
    private var isSFSymbol: Bool {
        emoji.contains(".") || sfSymbolsWithoutDots.contains(emoji.lowercased())
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(hex: color).opacity(0.73))
            
            // Handle both SF Symbols and emojis
            if isSFSymbol {
                Image(systemName: emoji)
                    .font(.system(.title3))
                    .foregroundStyle(.white)
            } else {
                Text(emoji)
                    .font(.system(.title3))
            }
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Category Icon View (reusable)

struct CategoryIconView: View {
    let icon: String
    
    // Known SF Symbols without dots
    private let sfSymbolsWithoutDots = [
        "laptopcomputer", "desktopcomputer", "macbook", "iphone", "ipad",
        "airpods", "homepod", "applewatch", "appletv", "airplane",
        "car", "bus", "tram", "bicycle", "scooter", "figure"
    ]
    
    private var isSFSymbol: Bool {
        icon.contains(".") || sfSymbolsWithoutDots.contains(icon.lowercased())
    }
    
    var body: some View {
        if isSFSymbol {
            Image(systemName: icon)
        } else {
            Text(icon)
        }
    }
}

// MARK: - Category Stepper View

struct LogCategoryStepperView: View {
    @Binding var categoryFilter: Category?
    let categories: [Category]
    
    @State private var income = false
    
    private var filteredCategories: [Category] {
        categories.filter { category in
            if income {
                return category.applicableTypes.contains(.income)
            } else {
                return category.applicableTypes.contains(.expense)
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Income/Expense Toggle
            Button {
                withAnimation(.easeIn(duration: 0.15)) {
                    income.toggle()
                    categoryFilter = filteredCategories.first
                }
            } label: {
                Image(systemName: income ? "plus" : "minus")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(income ? OGDesign.Colors.income : OGDesign.Colors.expense)
                    .padding(7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
                    .background(
                        (income ? OGDesign.Colors.income : OGDesign.Colors.expense).opacity(0.23),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            }
            
            // Category Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { value in
                    HStack(spacing: 8) {
                        ForEach(filteredCategories) { item in
                            HStack(spacing: 5) {
                                // Handle both SF Symbols and emojis
                                CategoryIconView(icon: item.icon)
                                    .font(.system(.footnote, design: .rounded).weight(.medium))
                                
                                Text(item.name)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                            }
                            .id(item.id)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .foregroundStyle(
                                categoryFilter?.id == item.id
                                    ? Color(hex: item.colorHex)
                                    : OGDesign.Colors.textPrimary
                            )
                            .background(
                                categoryFilter?.id == item.id
                                    ? Color(hex: item.colorHex).opacity(0.3)
                                    : OGDesign.Colors.backgroundPrimary,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay {
                                if categoryFilter?.id != item.id {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(OGDesign.Colors.glassBorder, lineWidth: 1.5)
                                }
                            }
                            .onTapGesture {
                                categoryFilter = item
                                withAnimation {
                                    value.scrollTo(item.id, anchor: .leading)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
    }
}

// MARK: - Income Toggle View

struct LogIncomeToggleView: View {
    @Binding var income: Bool
    
    @Namespace var animation
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Expense")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(income == false ? OGDesign.Colors.textPrimary : OGDesign.Colors.textSecondary)
                .padding(5.5)
                .padding(.horizontal, 8)
                .background {
                    if income == false {
                        Capsule()
                            .fill(OGDesign.Colors.glassFill)
                            .matchedGeometryEffect(id: "TAB1", in: animation)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeIn(duration: 0.15)) {
                        income = false
                    }
                }
            
            Text("Income")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(income == true ? OGDesign.Colors.textPrimary : OGDesign.Colors.textSecondary)
                .padding(5.5)
                .padding(.horizontal, 8)
                .background {
                    if income == true {
                        Capsule()
                            .fill(OGDesign.Colors.glassFill)
                            .matchedGeometryEffect(id: "TAB1", in: animation)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeIn(duration: 0.15)) {
                        income = true
                    }
                }
        }
        .padding(3)
        .overlay(Capsule().stroke(OGDesign.Colors.glassBorder.opacity(0.4), lineWidth: 1.3))
    }
}

// MARK: - Search View

struct LogSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    let transactions: [Transaction]
    let categories: [Category]
    
    @State private var searchQuery = ""
    @FocusState private var isFocused: Bool
    
    private var filteredTransactions: [Transaction] {
        guard !searchQuery.isEmpty else { return [] }
        
        return transactions.filter { transaction in
            // Search by note
            if transaction.note.localizedCaseInsensitiveContains(searchQuery) {
                return true
            }
            // Search by category name
            if let category = categories.first(where: { $0.id == transaction.categoryId }),
               category.name.localizedCaseInsensitiveContains(searchQuery) {
                return true
            }
            // Search by amount
            if let searchAmount = Double(searchQuery),
               NSDecimalNumber(decimal: transaction.amount).doubleValue == searchAmount {
                return true
            }
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 18) {
            // Search Bar
            HStack(spacing: 9) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary.opacity(0.8))
                    
                    TextField("Search entry by note", text: $searchQuery)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textPrimary)
                        .focused($isFocused)
                    
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(OGDesign.Colors.textSecondary)
                        }
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OGDesign.Colors.glassFill, in: RoundedRectangle(cornerRadius: 8))
                
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.textPrimary)
                }
            }
            
            // Results
            ScrollView {
                if searchQuery.isEmpty {
                    EmptyView()
                } else if filteredTransactions.isEmpty {
                    VStack(spacing: 2) {
                        Text("📭️")
                            .font(.system(size: 50))
                            .padding(.bottom, 15)
                        
                        Text("No entries found.")
                            .font(.system(.title3, design: .rounded).weight(.medium))
                            .foregroundStyle(OGDesign.Colors.textPrimary)
                        
                        Text("Try a different search query!")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                    }
                    .frame(alignment: .center)
                    .opacity(0.8)
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTransactions) { transaction in
                            LogTransactionRowView(
                                transaction: transaction,
                                category: categories.first(where: { $0.id == transaction.categoryId }),
                                onDelete: {}
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(15)
        .background(OGDesign.Colors.backgroundPrimary)
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    NavigationStack {
        TransactionListView()
    }
    .preferredColorScheme(.dark)
}
