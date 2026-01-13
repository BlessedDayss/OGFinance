//
//  StatisticsView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

// MARK: - Main Insights View

struct StatisticsView: View {
    @State private var transactions: [Transaction] = []
    @State private var showTimeMenu = false
    @AppStorage("chartTimeFrame") private var chartType = 2
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    @State private var refreshID = UUID()
    @State private var hasAppeared = false
    
    private var chartTypeString: String {
        switch chartType {
        case 1: return "week"
        case 2: return "month"
        case 3: return "year"
        default: return ""
        }
    }
    
    var body: some View {
        ZStack {
            // Static background for fast loading
            OGDesign.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            Group {
                if transactions.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
        }
        .task {
            await loadTransactions()
            withAnimation(.spring(duration: 0.3)) {
                hasAppeared = true
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundStyle(OGDesign.Colors.textTertiary)
            
            VStack(spacing: 8) {
                Text("Analyse Your Expenditure")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("As transactions start piling up")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 5) {
            // Header with glass effect
            HStack {
                Text("Insights")
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                
                Spacer()
                
                // Glass time selector button
                Button {
                    showTimeMenu = true
                } label: {
                    HStack(spacing: 4.5) {
                        Text(chartTypeString)
                            .font(.system(.body, design: .rounded).weight(.medium))
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.9))
                    .background {
                        // Glass button
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.ultraThinMaterial)
                            
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                        }
                    }
                }
                .confirmationDialog("Select Period", isPresented: $showTimeMenu) {
                    Button("Week") { chartType = 1; refreshID = UUID() }
                    Button("Month") { chartType = 2; refreshID = UUID() }
                    Button("Year") { chartType = 3; refreshID = UUID() }
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            .padding(.bottom, 20)
            .offset(y: hasAppeared ? 0 : -20)
            .opacity(hasAppeared ? 1 : 0)
            
            if chartType == 1 {
                WeekGraphContentView(transactions: transactions)
                    .id(refreshID)
                    .offset(y: hasAppeared ? 0 : 30)
                    .opacity(hasAppeared ? 1 : 0)
            } else if chartType == 2 {
                MonthGraphContentView(transactions: transactions)
                    .id(refreshID)
                    .offset(y: hasAppeared ? 0 : 30)
                    .opacity(hasAppeared ? 1 : 0)
            } else if chartType == 3 {
                YearGraphContentView(transactions: transactions)
                    .id(refreshID)
                    .offset(y: hasAppeared ? 0 : 30)
                    .opacity(hasAppeared ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadTransactions() async {
        do {
            transactions = try await DependencyContainer.shared.transactionRepository.fetchAll()
        } catch {
            print("Error loading transactions: \(error)")
        }
    }
}

// MARK: - Single Graph View

struct InsightsSingleGraphView: View {
    let transactions: [Transaction]
    let date: Date
    let type: Int
    
    @Binding var categoryFilterMode: Bool
    @Binding var selectedDate: Date?
    @Binding var income: Bool
    @Binding var incomeFiltering: Bool
    
    let selectedCategoryName: String
    let selectedCategoryAmount: Decimal
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    @State private var selectedDateAmount: Decimal = 0
    
    private var currencySymbol: String {
        CurrencyManager.symbol(for: currency)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        switch type {
        case 1:
            formatter.dateFormat = "d MMM"
            let endDate = calendar.date(byAdding: .day, value: 6, to: date) ?? date
            let startMonth = calendar.component(.month, from: date)
            let endMonth = calendar.component(.month, from: endDate)
            
            if startMonth == endMonth {
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "d"
                return dayFormatter.string(from: date) + " - " + formatter.string(from: endDate)
            } else {
                return formatter.string(from: date) + " - " + formatter.string(from: endDate)
            }
        case 2:
            formatter.dateFormat = "MMM yyyy"
        case 3:
            formatter.dateFormat = "yyyy"
        default:
            break
        }
        
        return formatter.string(from: date)
    }
    
    private var selectedDateString: String {
        guard let unwrappedDate = selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = type == 3 ? "MMM yyyy" : "d MMM yyyy"
        return formatter.string(from: unwrappedDate)
    }
    
    private var totalIncome: Decimal {
        transactions.filter { $0.type == .income && isInPeriod($0.date) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var totalExpenses: Decimal {
        transactions.filter { $0.type == .expense && isInPeriod($0.date) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var totalNet: Decimal {
        totalIncome - totalExpenses
    }
    
    private var netPositive: Bool {
        totalNet >= 0
    }
    
    private var average: Decimal {
        let days = type == 3 ? 12 : (type == 2 ? 30 : 7)
        guard days > 0 else { return 0 }
        return abs(totalNet) / Decimal(days)
    }
    
    private var incomeAverage: Decimal {
        let amount = income ? totalIncome : totalExpenses
        let days = type == 3 ? 12 : (type == 2 ? 30 : 7)
        guard days > 0 else { return 0 }
        return amount / Decimal(days)
    }
    
    private func isInPeriod(_ transactionDate: Date) -> Bool {
        let calendar = Calendar.current
        switch type {
        case 1:
            let endDate = calendar.date(byAdding: .day, value: 7, to: date) ?? date
            return transactionDate >= date && transactionDate < endDate
        case 2:
            return calendar.isDate(transactionDate, equalTo: date, toGranularity: .month)
        case 3:
            return calendar.isDate(transactionDate, equalTo: date, toGranularity: .year)
        default:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 1.3) {
                    Text(dateString)
                        .lineLimit(1)
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .layoutPriority(1)
                    
                    InsightsDollarText(
                        amount: abs(totalNet),
                        currencySymbol: currencySymbol,
                        net: netPositive
                    )
                    .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if categoryFilterMode {
                    VStack(alignment: .trailing, spacing: 1.3) {
                        Text(selectedCategoryName)
                            .lineLimit(1)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                        
                        InsightsDollarText(
                            amount: selectedCategoryAmount,
                            currencySymbol: currencySymbol
                        )
                        .layoutPriority(1)
                    }
                } else if selectedDate != nil {
                    VStack(alignment: .trailing, spacing: 1.3) {
                        Text(selectedDateString)
                            .lineLimit(1)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                        
                        InsightsDollarText(
                            amount: selectedDateAmount,
                            currencySymbol: currencySymbol
                        )
                        .layoutPriority(1)
                    }
                } else if incomeFiltering {
                    VStack(alignment: .trailing, spacing: 1.3) {
                        Text(type == 3 ? (income ? "Income/Mth" : "Spent/Mth") : (income ? "Income/Day" : "Spent/Day"))
                            .lineLimit(1)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                        
                        InsightsDollarText(
                            amount: incomeAverage,
                            currencySymbol: currencySymbol
                        )
                        .layoutPriority(1)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 1.3) {
                        Text(type == 3 ? "AVG/MTH" : "AVG/DAY")
                            .lineLimit(1)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                        
                        InsightsDollarText(
                            amount: average,
                            currencySymbol: currencySymbol,
                            net: netPositive
                        )
                        .layoutPriority(1)
                    }
                }
            }
            .padding(.bottom, 5)
            .onTapGesture {
                withAnimation(.easeIn(duration: 0.2)) {
                    selectedDate = nil
                }
            }
            
            HStack(spacing: 11) {
                InsightsSummaryBlock(
                    isIncome: true,
                    amountString: totalIncome.formatted(currencyCode: currency),
                    showOverlay: income && incomeFiltering
                ) {
                    withAnimation {
                        if incomeFiltering && income {
                            incomeFiltering = false
                        } else {
                            income = true
                            incomeFiltering = true
                        }
                    }
                    HapticManager.shared.light()
                }
                
                InsightsSummaryBlock(
                    isIncome: false,
                    amountString: totalExpenses.formatted(currencyCode: currency),
                    showOverlay: !income && incomeFiltering
                ) {
                    withAnimation {
                        if incomeFiltering && !income {
                            incomeFiltering = false
                        } else {
                            income = false
                            incomeFiltering = true
                        }
                    }
                    HapticManager.shared.light()
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 13)
            
            if incomeFiltering {
                InsightsBarChartView(
                    transactions: transactions,
                    date: date,
                    type: type,
                    income: income,
                    selectedDate: $selectedDate,
                    categoryFilterMode: $categoryFilterMode,
                    selectedDateAmount: $selectedDateAmount
                )
            }
        }
    }
}

// MARK: - Insights Dollar Text

struct InsightsDollarText: View {
    let amount: Decimal
    let currencySymbol: String
    var net: Bool? = nil
    
    private var symbol: String {
        if let netPositive = net {
            return netPositive ? "+\(currencySymbol)" : "-\(currencySymbol)"
        }
        return currencySymbol
    }
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 1.3) {
            Text(symbol)
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            Text(amount.formatted(.number.precision(.fractionLength(amount < 100 ? 2 : 0))))
                .font(.system(.title, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textPrimary)
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

// MARK: - Insights Summary Block (Liquid Glass Style)

struct InsightsSummaryBlock: View {
    let isIncome: Bool
    let amountString: String
    let showOverlay: Bool
    let action: () -> Void
    
    private var color: Color {
        isIncome ? OGDesign.Colors.income : OGDesign.Colors.expense
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isIncome ? "arrow.down" : "arrow.up")
                    .font(.system(.callout, design: .rounded).weight(.medium))
                
                Text(amountString)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Color tint overlay
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(showOverlay ? 0.15 : 0.08))
                    
                    // Gradient border
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    color.opacity(showOverlay ? 0.5 : 0.2),
                                    color.opacity(showOverlay ? 0.3 : 0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: showOverlay ? 1.5 : 0.8
                        )
                }
            }
            // Glow effect when selected
            .shadow(color: showOverlay ? color.opacity(0.3) : .clear, radius: 8, y: 0)
        }
        .buttonStyle(SummaryBlockButtonStyle())
    }
}

struct SummaryBlockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Bar Chart View

struct InsightsBarChartView: View {
    let transactions: [Transaction]
    let date: Date
    let type: Int
    let income: Bool
    @Binding var selectedDate: Date?
    @Binding var categoryFilterMode: Bool
    @Binding var selectedDateAmount: Decimal
    
    private var dates: [Date] {
        let calendar = Calendar.current
        switch type {
        case 1:
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: date) }
        case 2:
            let range = calendar.range(of: .day, in: .month, for: date) ?? 1..<31
            return range.compactMap { day -> Date? in
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = day
                return calendar.date(from: components)
            }
        case 3:
            return (0..<12).compactMap { month -> Date? in
                var components = calendar.dateComponents([.year], from: date)
                components.month = month + 1
                return calendar.date(from: components)
            }
        default:
            return []
        }
    }
    
    private var dateDictionary: [Date: Decimal] {
        var dict = [Date: Decimal]()
        let calendar = Calendar.current
        
        for d in dates {
            let filtered = transactions.filter { transaction in
                let isCorrectType = income ? transaction.type == .income : transaction.type == .expense
                let isInDate: Bool
                
                switch type {
                case 1, 2:
                    isInDate = calendar.isDate(transaction.date, inSameDayAs: d)
                case 3:
                    isInDate = calendar.isDate(transaction.date, equalTo: d, toGranularity: .month)
                default:
                    isInDate = false
                }
                
                return isCorrectType && isInDate
            }
            
            dict[d] = filtered.reduce(Decimal.zero) { $0 + $1.amount }
        }
        
        return dict
    }
    
    private var maximum: Decimal {
        dateDictionary.values.max() ?? 1
    }
    
    private var maxInt: Int {
        let max = maximum * 1.1
        let maxDouble = NSDecimalNumber(decimal: max).doubleValue
        guard maxDouble.isFinite && maxDouble <= Double(Int.max) else {
            return Int.max / 10 // Safe fallback
        }
        return Int(ceil(maxDouble / 10) * 10)
    }
    
    private var average: Decimal {
        let total = dateDictionary.values.reduce(Decimal.zero, +)
        let count = dateDictionary.values.filter { $0 > 0 }.count
        guard count > 0 else { return 0 }
        return total / Decimal(count)
    }
    
    private let barHeight: CGFloat = 150
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top, spacing: type == 2 ? 2 : 7) {
                VStack(alignment: .leading) {
                    Text(getMaxText(maxInt))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("0")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                }
                .frame(height: barHeight)
                .padding(.trailing, 3)
                
                HStack(alignment: .top, spacing: type == 2 ? 2 : type == 3 ? 4 : 7) {
                    ForEach(Array(dates.enumerated()), id: \.element) { index, day in
                        VStack(spacing: 5) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(OGDesign.Colors.glassFill)
                                    .frame(height: barHeight)
                                
                                AnimatedBarView(index: index)
                                    .frame(height: getBarHeight(dateDictionary[day] ?? 0))
                                    .opacity(selectedDate == nil ? 1 : (selectedDate == day ? 1 : 0.4))
                            }
                            
                            if shouldShowLabel(index) {
                                Text(getLabel(day, index: index))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(OGDesign.Colors.textSecondary)
                            }
                        }
                        .opacity(day > Date.now ? 0.3 : 1)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(!(day > Date.now))
                        .onTapGesture {
                            withAnimation(.easeIn(duration: 0.2)) {
                                if selectedDate == day {
                                    selectedDate = nil
                                    categoryFilterMode = false
                                } else {
                                    selectedDate = day
                                    categoryFilterMode = false
                                    selectedDateAmount = dateDictionary[day] ?? 0
                                }
                            }
                            HapticManager.shared.selection_()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
            if average > 0 {
                AverageLineIndicator(maxInt: maxInt, average: average, barHeight: barHeight)
            }
        }
        .onChange(of: selectedDate) { _, _ in
            if let date = selectedDate {
                selectedDateAmount = dateDictionary[date] ?? 0
            }
        }
    }
    
    private func shouldShowLabel(_ index: Int) -> Bool {
        switch type {
        case 1: return true
        case 2: return index == 0 || (index + 1) % 7 == 0 || index == dates.count - 1
        case 3: return [0, 3, 6, 9].contains(index)
        default: return false
        }
    }
    
    private func getLabel(_ date: Date, index: Int) -> String {
        switch type {
        case 1:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return String(formatter.string(from: date).prefix(1))
        case 2:
            // Show the actual day of month
            let calendar = Calendar.current
            let day = calendar.component(.day, from: date)
            return "\(day)"
        case 3:
            let monthNames = ["Jan", "Apr", "Jul", "Oct"]
            let monthIndex = [0, 3, 6, 9]
            if let idx = monthIndex.firstIndex(of: index) {
                return monthNames[idx]
            }
            return ""
        default:
            return ""
        }
    }
    
    private func getBarHeight(_ value: Decimal) -> CGFloat {
        guard maxInt > 0 else { return 0 }
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        return CGFloat(doubleValue / Double(maxInt)) * barHeight
    }
    
    private func getMaxText(_ maxi: Int) -> String {
        if maxi == 0 { return "10" }
        
        if maxi >= 1_000_000 {
            return "\(maxi / 1_000_000)M"
        } else if maxi >= 1000 {
            let thousands = Double(maxi) / 1000.0
            if thousands >= 100 {
                return "\(Int(thousands))k"
            } else if thousands >= 10 {
                return "\(Int(thousands))k"
            } else {
                return String(format: "%.1fk", thousands)
            }
        }
        return String(maxi)
    }
}

// MARK: - Animated Bar View

struct AnimatedBarView: View {
    let index: Int
    @State private var showBar = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(OGDesign.Colors.textPrimary)
                .frame(height: showBar ? nil : 0, alignment: .bottom)
        }
        .onAppear {
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8).delay(Double(index) * 0.05)) {
                showBar = true
            }
        }
    }
}

// MARK: - Average Line Indicator

struct AverageLineIndicator: View {
    let maxInt: Int
    let average: Decimal
    let barHeight: CGFloat
    
    private var offset: CGFloat {
        guard maxInt > 0 else { return 0 }
        let avgDouble = NSDecimalNumber(decimal: average).doubleValue
        let shiftedAmount = (avgDouble / Double(maxInt)) * barHeight
        return barHeight - shiftedAmount - 10
    }
    
    private var averageText: String {
        let avgDouble = NSDecimalNumber(decimal: average).doubleValue
        if avgDouble >= 1000 {
            return String(format: "%.1fk", avgDouble / 1000)
        }
        guard avgDouble.isFinite && avgDouble <= Double(Int.max) && avgDouble >= Double(Int.min) else {
            return "0"
        }
        return String(Int(avgDouble))
    }
    
    private var shouldShow: Bool {
        let ratio = NSDecimalNumber(decimal: average).doubleValue / Double(maxInt)
        return ratio >= 0.1 && ratio <= 0.9
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text(averageText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(OGDesign.Colors.backgroundPrimary, in: RoundedRectangle(cornerRadius: 4))
            
            Line()
                .stroke(OGDesign.Colors.textSecondary, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5]))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .offset(y: offset)
        .opacity(shouldShow ? 1 : 0)
    }
}

// MARK: - Line Shape

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - Horizontal Category Chart

struct InsightsHorizontalCategoryChart: View {
    let transactions: [Transaction]
    let date: Date
    let type: Int
    let income: Bool
    @Binding var categoryFilterMode: Bool
    @Binding var categoryFilter: UUID?
    @Binding var selectedDate: Date?
    @Binding var chosenAmount: Decimal
    @Binding var chosenName: String
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    @State private var categories: [CategoryStatData] = []
    
    private var currencySymbol: String {
        CurrencyManager.symbol(for: currency)
    }
    
    var body: some View {
        Group {
            if !categories.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    if !categoryFilterMode {
                        Text("Categories")
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                        
                        GeometryReader { proxy in
                            HStack(spacing: proxy.size.width * 0.015) {
                                ForEach(categories) { category in
                                    if category.percent >= 0.005 {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(hex: category.colorHex))
                                            .frame(width: (proxy.size.width * (1.0 - (0.015 * Double(categories.count - 1)))) * category.percent)
                                            .opacity(categoryFilterMode ? (categoryFilter == category.id ? 1 : 0.5) : 1)
                                            .overlay {
                                                if categoryFilterMode && categoryFilter == category.id {
                                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                        .stroke(OGDesign.Colors.backgroundPrimary, lineWidth: 1.5)
                                                }
                                            }
                                            .onTapGesture {
                                                withAnimation(.easeInOut) {
                                                    if categoryFilter == category.id {
                                                        selectedDate = nil
                                                        categoryFilterMode = false
                                                        categoryFilter = nil
                                                    } else {
                                                        selectedDate = nil
                                                        categoryFilterMode = true
                                                        categoryFilter = category.id
                                                        chosenAmount = category.amount
                                                        chosenName = category.name
                                                    }
                                                }
                                                HapticManager.shared.selection_()
                                            }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 17)
                        .padding(.bottom, 10)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(categories) { category in
                                if !categoryFilterMode || categoryFilter == category.id {
                                    CategoryStatRow(
                                        category: category,
                                        isSelected: categoryFilterMode && categoryFilter == category.id,
                                        currencySymbol: currencySymbol
                                    ) {
                                        withAnimation(.easeInOut) {
                                            if categoryFilterMode && categoryFilter == category.id {
                                                selectedDate = nil
                                                categoryFilterMode = false
                                                categoryFilter = nil
                                            } else if !categoryFilterMode {
                                                selectedDate = nil
                                                categoryFilterMode = true
                                                categoryFilter = category.id
                                                chosenAmount = category.amount
                                                chosenName = category.name
                                            }
                                        }
                                        HapticManager.shared.selection_()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadCategories()
        }
    }
    
    private func loadCategories() async {
        let categoryRepo = DependencyContainer.shared.categoryRepository
        let allCategories = (try? await categoryRepo.fetchAll()) ?? []
        
        let filteredTransactions = transactions.filter { transaction in
            let isCorrectType = income ? transaction.type == .income : transaction.type == .expense
            return isCorrectType && isInPeriod(transaction.date)
        }
        
        let total = filteredTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        guard total > 0 else { return }
        
        var stats = [CategoryStatData]()
        
        for cat in allCategories {
            let catTransactions = filteredTransactions.filter { $0.categoryId == cat.id }
            let amount = catTransactions.reduce(Decimal.zero) { $0 + $1.amount }
            
            if amount > 0 {
                let percent = NSDecimalNumber(decimal: amount / total).doubleValue
                stats.append(CategoryStatData(
                    id: cat.id,
                    name: cat.name,
                    icon: cat.icon,
                    colorHex: cat.colorHex,
                    amount: amount,
                    percent: percent
                ))
            }
        }
        
        categories = stats.sorted { $0.percent > $1.percent }
    }
    
    private func isInPeriod(_ transactionDate: Date) -> Bool {
        let calendar = Calendar.current
        switch type {
        case 1:
            let endDate = calendar.date(byAdding: .day, value: 7, to: date) ?? date
            return transactionDate >= date && transactionDate < endDate
        case 2:
            return calendar.isDate(transactionDate, equalTo: date, toGranularity: .month)
        case 3:
            return calendar.isDate(transactionDate, equalTo: date, toGranularity: .year)
        default:
            return false
        }
    }
}

// MARK: - Category Stat Data

struct CategoryStatData: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let amount: Decimal
    let percent: Double
}

// MARK: - Category Stat Row

struct CategoryStatRow: View {
    let category: CategoryStatData
    let isSelected: Bool
    let currencySymbol: String
    let action: () -> Void
    
    private var boxColor: Color {
        Color(hex: category.colorHex)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text("\(category.icon) \(category.name)")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(currencySymbol)\(category.amount.formatted(.number.precision(.fractionLength(category.amount < 100 ? 2 : 0))))")
                .font(.system(isSelected ? .title3 : .body, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .lineLimit(1)
                .layoutPriority(1)
            
            if isSelected {
                Button(action: action) {
                    Image(systemName: "xmark")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .padding(5)
                        .background(OGDesign.Colors.glassFill, in: Circle())
                }
            } else {
                Text("\(Int(category.percent * 100))%")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(boxColor)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(boxColor.opacity(0.23), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.vertical, isSelected ? 10 : 5)
        .padding(.horizontal, isSelected ? 10 : 0)
        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? OGDesign.Colors.glassFill : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isSelected ? OGDesign.Colors.glassBorder : Color.clear, lineWidth: 1.3))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// MARK: - Swipe Arrow View

struct SwipeArrowIndicator: View {
    let left: Bool
    let swipeString: String
    let changeTime: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: left ? "arrow.backward.circle.fill" : "arrow.forward.circle.fill")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(changeTime ? OGDesign.Colors.textPrimary : OGDesign.Colors.glassFill)
            
            Text(swipeString)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(changeTime ? OGDesign.Colors.textPrimary : OGDesign.Colors.glassFill)
        }
        .drawingGroup()
    }
}

// MARK: - Swipe End View

struct SwipeEndIndicator: View {
    let left: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: left ? "eyeglasses" : "sun.haze.fill")
                .font(.system(.title2, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            Text(left ? "That's all, buddy." : "Into the unknown.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .frame(width: 90)
                .multilineTextAlignment(.center)
                .foregroundStyle(OGDesign.Colors.textSecondary)
        }
        .opacity(0.8)
        .drawingGroup()
    }
}

// MARK: - Week Graph Content View

struct WeekGraphContentView: View {
    let transactions: [Transaction]
    
    @State private var categoryFilterMode = false
    @State private var categoryFilter: UUID?
    @State private var selectedDate: Date?
    @State private var showingWeek = Date()
    @State private var chosenCategoryName = ""
    @State private var chosenCategoryAmount: Decimal = 0
    @State private var income = false
    @State private var incomeFiltering = true
    @State private var offset: CGFloat = 0
    @State private var changeDate = false
    @GestureState private var isDragging = false
    @State private var refreshID = UUID()
    
    private var startOfCurrentWeek: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    private var startOfLastWeek: Date {
        guard let earliest = transactions.min(by: { $0.date < $1.date }) else { return Date() }
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: earliest.date)
        return calendar.date(from: components) ?? Date()
    }
    
    private var changeTime: Bool {
        if offset < -(UIScreen.main.bounds.width * 0.25) && showingWeek != startOfCurrentWeek {
            return true
        } else if offset > (UIScreen.main.bounds.width * 0.25) && showingWeek != startOfLastWeek {
            return true
        }
        return false
    }
    
    private var swipeStrings: (backward: String, forward: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let calendar = Calendar.current
        let back = calendar.date(byAdding: .day, value: -7, to: showingWeek) ?? Date()
        let forward = calendar.date(byAdding: .day, value: 7, to: showingWeek) ?? Date()
        return (formatter.string(from: back), formatter.string(from: forward))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    InsightsSingleGraphView(
                        transactions: transactions,
                        date: showingWeek,
                        type: 1,
                        categoryFilterMode: $categoryFilterMode,
                        selectedDate: $selectedDate,
                        income: $income,
                        incomeFiltering: $incomeFiltering,
                        selectedCategoryName: chosenCategoryName,
                        selectedCategoryAmount: chosenCategoryAmount
                    )
                    .id(refreshID)
                    .offset(x: offset)
                    
                    if !changeDate {
                        HStack {
                            if showingWeek != startOfLastWeek {
                                SwipeArrowIndicator(left: true, swipeString: swipeStrings.backward.uppercased(), changeTime: changeTime)
                                    .offset(x: -100)
                                    .offset(x: min(100, offset))
                            } else {
                                SwipeEndIndicator(left: true)
                                    .offset(x: -120)
                                    .offset(x: min(120, offset))
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            if showingWeek != startOfCurrentWeek {
                                SwipeArrowIndicator(left: false, swipeString: swipeStrings.forward.uppercased(), changeTime: changeTime)
                                    .offset(x: 100)
                                    .offset(x: max(-100, offset))
                            } else {
                                SwipeEndIndicator(left: false)
                                    .offset(x: 120)
                                    .offset(x: max(-120, offset))
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 30)
                .simultaneousGesture(createSwipeGesture())
                .onChange(of: changeTime) { _, newValue in
                    if newValue { HapticManager.shared.light() }
                }
                .onChange(of: isDragging) { _, newValue in
                    if !newValue && !changeDate {
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    }
                }
                .onChange(of: showingWeek) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                    refreshID = UUID()
                }
                .onChange(of: income) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .onChange(of: incomeFiltering) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .padding(.bottom, incomeFiltering ? 5 : 10)
                .onAppear { showingWeek = startOfCurrentWeek }
                
                if incomeFiltering && selectedDate == nil {
                    InsightsHorizontalCategoryChart(
                        transactions: transactions,
                        date: showingWeek,
                        type: 1,
                        income: income,
                        categoryFilterMode: $categoryFilterMode,
                        categoryFilter: $categoryFilter,
                        selectedDate: $selectedDate,
                        chosenAmount: $chosenCategoryAmount,
                        chosenName: $chosenCategoryName
                    )
                    .padding(.horizontal, 30)
                    .padding(.bottom, 100)
                    .id(refreshID)
                }
            }
        }
    }
    
    private func createSwipeGesture() -> some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                withAnimation {
                    if value.translation.width < 0 && showingWeek != startOfCurrentWeek {
                        offset = value.translation.width * 0.9
                    } else if value.translation.width < 0 && showingWeek == startOfCurrentWeek {
                        offset = value.translation.width * 0.5
                    } else if value.translation.width > 0 && showingWeek != startOfLastWeek {
                        offset = value.translation.width * 0.9
                    } else if value.translation.width > 0 && showingWeek == startOfLastWeek {
                        offset = value.translation.width * 0.5
                    }
                }
            }
            .onEnded { _ in
                if changeTime {
                    if offset < 0 && showingWeek != startOfCurrentWeek {
                        changeDate = true
                        offset = UIScreen.main.bounds.width
                        showingWeek = Calendar.current.date(byAdding: .day, value: 7, to: showingWeek) ?? Date()
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    } else if offset > 0 && showingWeek != startOfLastWeek {
                        changeDate = true
                        offset = -UIScreen.main.bounds.width
                        showingWeek = Calendar.current.date(byAdding: .day, value: -7, to: showingWeek) ?? Date()
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    }
                    changeDate = false
                }
            }
    }
}

// MARK: - Month Graph Content View

struct MonthGraphContentView: View {
    let transactions: [Transaction]
    
    @State private var categoryFilterMode = false
    @State private var categoryFilter: UUID?
    @State private var selectedDate: Date?
    @State private var showingMonth = Date()
    @State private var chosenCategoryName = ""
    @State private var chosenCategoryAmount: Decimal = 0
    @State private var income = false
    @State private var incomeFiltering = true
    @State private var offset: CGFloat = 0
    @State private var changeDate = false
    @GestureState private var isDragging = false
    @State private var refreshID = UUID()
    
    private var startOfCurrentMonth: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    private var startOfLastMonth: Date {
        guard let earliest = transactions.min(by: { $0.date < $1.date }) else { return Date() }
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: earliest.date)
        return calendar.date(from: components) ?? Date()
    }
    
    private var changeTime: Bool {
        if offset < -(UIScreen.main.bounds.width * 0.25) && showingMonth != startOfCurrentMonth {
            return true
        } else if offset > (UIScreen.main.bounds.width * 0.25) && showingMonth != startOfLastMonth {
            return true
        }
        return false
    }
    
    private var swipeStrings: (backward: String, forward: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        let calendar = Calendar.current
        let back = calendar.date(byAdding: .month, value: -1, to: showingMonth) ?? Date()
        let forward = calendar.date(byAdding: .month, value: 1, to: showingMonth) ?? Date()
        return (formatter.string(from: back), formatter.string(from: forward))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    InsightsSingleGraphView(
                        transactions: transactions,
                        date: showingMonth,
                        type: 2,
                        categoryFilterMode: $categoryFilterMode,
                        selectedDate: $selectedDate,
                        income: $income,
                        incomeFiltering: $incomeFiltering,
                        selectedCategoryName: chosenCategoryName,
                        selectedCategoryAmount: chosenCategoryAmount
                    )
                    .id(refreshID)
                    .offset(x: offset)
                    
                    if !changeDate {
                        HStack {
                            if showingMonth != startOfLastMonth {
                                SwipeArrowIndicator(left: true, swipeString: swipeStrings.backward.uppercased(), changeTime: changeTime)
                                    .offset(x: -100)
                                    .offset(x: min(100, offset))
                            } else {
                                SwipeEndIndicator(left: true)
                                    .offset(x: -120)
                                    .offset(x: min(120, offset))
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            if showingMonth != startOfCurrentMonth {
                                SwipeArrowIndicator(left: false, swipeString: swipeStrings.forward.uppercased(), changeTime: changeTime)
                                    .offset(x: 100)
                                    .offset(x: max(-100, offset))
                            } else {
                                SwipeEndIndicator(left: false)
                                    .offset(x: 120)
                                    .offset(x: max(-120, offset))
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 30)
                .simultaneousGesture(createSwipeGesture())
                .onChange(of: changeTime) { _, newValue in
                    if newValue { HapticManager.shared.light() }
                }
                .onChange(of: isDragging) { _, newValue in
                    if !newValue && !changeDate {
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    }
                }
                .onChange(of: showingMonth) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                    refreshID = UUID()
                }
                .onChange(of: income) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .onChange(of: incomeFiltering) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .padding(.bottom, incomeFiltering ? 5 : 20)
                .onAppear { showingMonth = startOfCurrentMonth }
                
                if incomeFiltering && selectedDate == nil {
                    InsightsHorizontalCategoryChart(
                        transactions: transactions,
                        date: showingMonth,
                        type: 2,
                        income: income,
                        categoryFilterMode: $categoryFilterMode,
                        categoryFilter: $categoryFilter,
                        selectedDate: $selectedDate,
                        chosenAmount: $chosenCategoryAmount,
                        chosenName: $chosenCategoryName
                    )
                    .padding(.horizontal, 30)
                    .padding(.bottom, 100)
                    .id(refreshID)
                }
            }
        }
    }
    
    private func createSwipeGesture() -> some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                withAnimation {
                    if value.translation.width < 0 && showingMonth != startOfCurrentMonth {
                        offset = value.translation.width * 0.9
                    } else if value.translation.width < 0 && showingMonth == startOfCurrentMonth {
                        offset = value.translation.width * 0.5
                    } else if value.translation.width > 0 && showingMonth != startOfLastMonth {
                        offset = value.translation.width * 0.9
                    } else if value.translation.width > 0 && showingMonth == startOfLastMonth {
                        offset = value.translation.width * 0.5
                    }
                }
            }
            .onEnded { _ in
                if changeTime {
                    if offset < 0 && showingMonth != startOfCurrentMonth {
                        changeDate = true
                        offset = UIScreen.main.bounds.width
                        showingMonth = Calendar.current.date(byAdding: .month, value: 1, to: showingMonth) ?? Date()
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    } else if offset > 0 && showingMonth != startOfLastMonth {
                        changeDate = true
                        offset = -UIScreen.main.bounds.width
                        showingMonth = Calendar.current.date(byAdding: .month, value: -1, to: showingMonth) ?? Date()
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    }
                    changeDate = false
                }
            }
    }
}

// MARK: - Year Graph Content View

struct YearGraphContentView: View {
    let transactions: [Transaction]
    
    @State private var categoryFilterMode = false
    @State private var categoryFilter: UUID?
    @State private var selectedDate: Date?
    @State private var showingYear = Date()
    @State private var chosenCategoryName = ""
    @State private var chosenCategoryAmount: Decimal = 0
    @State private var income = false
    @State private var incomeFiltering = true
    @State private var offset: CGFloat = 0
    @State private var changeDate = false
    @GestureState private var isDragging = false
    @State private var refreshID = UUID()
    
    private var startOfCurrentYear: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    private var startOfLastYear: Date {
        guard let earliest = transactions.min(by: { $0.date < $1.date }) else { return Date() }
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year], from: earliest.date)
        return calendar.date(from: components) ?? Date()
    }
    
    private var changeTime: Bool {
        if offset < -(UIScreen.main.bounds.width * 0.25) && showingYear != startOfCurrentYear {
            return true
        } else if offset > (UIScreen.main.bounds.width * 0.25) && showingYear != startOfLastYear {
            return true
        }
        return false
    }
    
    private var swipeStrings: (backward: String, forward: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let calendar = Calendar.current
        let back = calendar.date(byAdding: .year, value: -1, to: showingYear) ?? Date()
        let forward = calendar.date(byAdding: .year, value: 1, to: showingYear) ?? Date()
        return (formatter.string(from: back), formatter.string(from: forward))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    InsightsSingleGraphView(
                        transactions: transactions,
                        date: showingYear,
                        type: 3,
                        categoryFilterMode: $categoryFilterMode,
                        selectedDate: $selectedDate,
                        income: $income,
                        incomeFiltering: $incomeFiltering,
                        selectedCategoryName: chosenCategoryName,
                        selectedCategoryAmount: chosenCategoryAmount
                    )
                    .id(refreshID)
                    .offset(x: offset)
                    
                    if !changeDate {
                        HStack {
                            if showingYear != startOfLastYear {
                                SwipeArrowIndicator(left: true, swipeString: swipeStrings.backward.uppercased(), changeTime: changeTime)
                                    .offset(x: -100)
                                    .offset(x: min(100, offset))
                            } else {
                                SwipeEndIndicator(left: true)
                                    .offset(x: -120)
                                    .offset(x: min(120, offset))
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            if showingYear != startOfCurrentYear {
                                SwipeArrowIndicator(left: false, swipeString: swipeStrings.forward.uppercased(), changeTime: changeTime)
                                    .offset(x: 100)
                                    .offset(x: max(-100, offset))
                            } else {
                                SwipeEndIndicator(left: false)
                                    .offset(x: 120)
                                    .offset(x: max(-120, offset))
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 30)
                .simultaneousGesture(createSwipeGesture())
                .onChange(of: changeTime) { _, newValue in
                    if newValue { HapticManager.shared.light() }
                }
                .onChange(of: isDragging) { _, newValue in
                    if !newValue && !changeDate {
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    }
                }
                .onChange(of: showingYear) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                    refreshID = UUID()
                }
                .onChange(of: income) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .onChange(of: incomeFiltering) { _, _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .padding(.bottom, incomeFiltering ? 5 : 20)
                .onAppear { showingYear = startOfCurrentYear }
                
                if incomeFiltering && selectedDate == nil {
                    InsightsHorizontalCategoryChart(
                        transactions: transactions,
                        date: showingYear,
                        type: 3,
                        income: income,
                        categoryFilterMode: $categoryFilterMode,
                        categoryFilter: $categoryFilter,
                        selectedDate: $selectedDate,
                        chosenAmount: $chosenCategoryAmount,
                        chosenName: $chosenCategoryName
                    )
                    .padding(.horizontal, 30)
                    .padding(.bottom, 100)
                    .id(refreshID)
                }
            }
        }
    }
    
    private func createSwipeGesture() -> some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                withAnimation {
                    if value.translation.width < 0 && showingYear != startOfCurrentYear {
                        offset = value.translation.width * 0.9
                    } else if value.translation.width < 0 && showingYear == startOfCurrentYear {
                        offset = value.translation.width * 0.5
                    } else if value.translation.width > 0 && showingYear != startOfLastYear {
                        offset = value.translation.width * 0.9
                    } else if value.translation.width > 0 && showingYear == startOfLastYear {
                        offset = value.translation.width * 0.5
                    }
                }
            }
            .onEnded { _ in
                if changeTime {
                    if offset < 0 && showingYear != startOfCurrentYear {
                        changeDate = true
                        offset = UIScreen.main.bounds.width
                        showingYear = Calendar.current.date(byAdding: .year, value: 1, to: showingYear) ?? Date()
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    } else if offset > 0 && showingYear != startOfLastYear {
                        changeDate = true
                        offset = -UIScreen.main.bounds.width
                        showingYear = Calendar.current.date(byAdding: .year, value: -1, to: showingYear) ?? Date()
                        withAnimation(.easeInOut(duration: 0.3)) { offset = 0 }
                    }
                    changeDate = false
                }
            }
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .preferredColorScheme(.dark)
}
