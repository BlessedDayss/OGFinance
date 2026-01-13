//
//  StatisticsView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI
import Charts

// MARK: - Statistics View

struct StatisticsView: View {
    
    // MARK: - State
    
    @State private var statistics: Statistics?
    @State private var isLoading = true
    @State private var chartType = 2 // 1: week, 2: month, 3: year
    @State private var showTimeMenu = false
    @State private var refreshID = UUID()
    
    private var chartTypeString: String {
        switch chartType {
        case 1: return "week"
        case 2: return "month"
        case 3: return "year"
        default: return "month"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            if isLoading && statistics == nil {
                emptyStateView
            } else if let stats = statistics, !stats.categoryBreakdown.isEmpty {
                insightsContentView(stats)
            } else {
                emptyStateView
            }
        }
        .task {
            await loadStatistics()
        }
        .onChange(of: chartType) { _, _ in
            Task { await loadStatistics() }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 5) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundStyle(OGDesign.Colors.textTertiary)
                .padding(.bottom, 20)
            
            Text("Analyse Your Expenditure")
                .font(.system(.title2, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Text("As transactions start piling up")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 30)
        .frame(height: 250, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OGDesign.Colors.backgroundPrimary)
    }
    
    // MARK: - Insights Content
    
    private func insightsContentView(_ stats: Statistics) -> some View {
        VStack(spacing: 5) {
            // Header
            headerView
            
            // Graph Content
            if chartType == 1 {
                WeekGraphContentView(statistics: stats)
                    .id(refreshID)
            } else if chartType == 2 {
                MonthGraphContentView(statistics: stats)
                    .id(refreshID)
            } else {
                YearGraphContentView(statistics: stats)
                    .id(refreshID)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OGDesign.Colors.backgroundPrimary)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Insights")
                .font(.system(.title, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textPrimary)
            
            Spacer()
            
            // Period Selector Button
            Button {
                showTimeMenu = true
            } label: {
                HStack(spacing: 4.5) {
                    Text(chartTypeString)
                        .font(.system(.body, design: .rounded).weight(.medium))
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                }
                .padding(3)
                .padding(.horizontal, 6)
                .foregroundStyle(OGDesign.Colors.textPrimary.opacity(0.9))
                .background(OGDesign.Colors.glassFill, in: RoundedRectangle(cornerRadius: 6))
            }
            .confirmationDialog("Select Period", isPresented: $showTimeMenu) {
                Button("Week") { chartType = 1 }
                Button("Month") { chartType = 2 }
                Button("Year") { chartType = 3 }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Data Loading
    
    private func loadStatistics() async {
        isLoading = true
        
        do {
            let period: StatisticsPeriod = chartType == 1 ? .week : (chartType == 2 ? .month : .year)
            let useCase = DependencyContainer.shared.makeGetStatisticsUseCase()
            statistics = try await useCase.execute(for: period)
            refreshID = UUID()
        } catch {
            print("Error loading statistics: \(error)")
        }
        
        isLoading = false
    }
}

struct SingleGraphView: View {
    let statistics: Statistics
    let chartType: Int
    
    @Binding var income: Bool
    @Binding var incomeFiltering: Bool
    @Binding var selectedDate: Date?
    @State private var categoryFilterMode = false
    
    private var dateString: String {
        let formatter = DateFormatter()
        switch chartType {
        case 1:
            let calendar = Calendar.current
            formatter.dateFormat = "d MMM"
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? Date()
            return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
        case 2:
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: Date())
        case 3:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: Date())
        default:
            return ""
        }
    }
    
    private var netAmount: Decimal {
        statistics.totalIncome - statistics.totalExpenses
    }
    
    private var isPositive: Bool {
        netAmount >= 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header Row
            HStack {
                VStack(alignment: .leading, spacing: 1.3) {
                    Text(dateString)
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .lineLimit(1)
                    
                    // Net Amount Display
                    InsightsAmountView(
                        amount: abs(netAmount),
                        isPositive: isPositive
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Average Display
                VStack(alignment: .trailing, spacing: 1.3) {
                    Text(chartType == 3 ? "AVG/MTH" : "AVG/DAY")
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .lineLimit(1)
                    
                    InsightsAmountView(
                        amount: abs(statistics.dailyAverages.averageNetChange),
                        isPositive: statistics.dailyAverages.averageNetChange >= 0
                    )
                }
            }
            .padding(.bottom, 5)
            
            // Income/Expense Toggle
            HStack(spacing: 11) {
                InsightsSummaryBlock(
                    isIncome: true,
                    amount: statistics.totalIncome.formatted(currencyCode: "USD"),
                    isSelected: income && incomeFiltering
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
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
                    amount: statistics.totalExpenses.formatted(currencyCode: "USD"),
                    isSelected: !income && incomeFiltering
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
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
            
            // Bar Chart (when filtering is active)
            if incomeFiltering {
                AnimatedInsightsBarChart(
                    chartType: chartType,
                    isIncome: income,
                    selectedDate: $selectedDate
                )
                .frame(height: 170)
            }
        }
    }
}


struct InsightsAmountView: View {
    let amount: Decimal
    let isPositive: Bool
    
    private var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 1.3) {
            Text(isPositive ? "+\(currencySymbol)" : "-\(currencySymbol)")
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            Text(amount.formatted(.number.precision(.fractionLength(0...0))))
                .font(.system(.title, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textPrimary)
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}


struct InsightsSummaryBlock: View {
    let isIncome: Bool
    let amount: String
    let isSelected: Bool
    let action: () -> Void
    
    private var color: Color {
        isIncome ? OGDesign.Colors.income : OGDesign.Colors.expense
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isIncome ? "arrow.down" : "arrow.up")
                    .font(.system(.callout, design: .rounded).weight(.medium))
                
                Text(amount)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(color.opacity(isSelected ? 0.2 : 0.1), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(color.opacity(0.5), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Animated Insights Bar Chart

struct AnimatedInsightsBarChart: View {
    let chartType: Int
    let isIncome: Bool
    @Binding var selectedDate: Date?
    
    @State private var barHeights: [CGFloat] = []
    
    private var barCount: Int {
        switch chartType {
        case 1: return 7
        case 2: return 31
        case 3: return 12
        default: return 7
        }
    }
    
    private var color: Color {
        isIncome ? OGDesign.Colors.income : OGDesign.Colors.expense
    }
    
    private let weekLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private let yearLabels = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    
    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = chartType == 2 ? 2 : 6
            let barWidth = (geometry.size.width - CGFloat(barCount - 1) * spacing - 50) / CGFloat(barCount)
            
            HStack(alignment: .top, spacing: 3) {
                // Y-axis labels
                VStack {
                    Text("100")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                    Spacer()
                    Text("0")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                }
                .frame(height: 150)
                .padding(.trailing, 3)
                
                // Bars
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { index in
                        VStack(spacing: 5) {
                            ZStack(alignment: .bottom) {
                                // Background bar
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(OGDesign.Colors.glassFill)
                                    .frame(width: barWidth, height: 150)
                                
                                // Animated bar
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(color)
                                    .frame(width: barWidth, height: index < barHeights.count ? barHeights[index] : 0)
                            }
                            
                            // Label
                            if shouldShowLabel(index) {
                                Text(getLabel(index))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(OGDesign.Colors.textTertiary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            generateBars()
        }
    }
    
    private func shouldShowLabel(_ index: Int) -> Bool {
        switch chartType {
        case 1: return true
        case 2: return [0, 7, 14, 21, 28].contains(index)
        case 3: return [0, 3, 6, 9].contains(index)
        default: return false
        }
    }
    
    private func getLabel(_ index: Int) -> String {
        switch chartType {
        case 1: return weekLabels[index]
        case 2: return "\(index + 1)"
        case 3: return yearLabels[index]
        default: return ""
        }
    }
    
    private func generateBars() {
        barHeights = []
        for i in 0..<barCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                    barHeights.append(CGFloat.random(in: 20...140))
                }
            }
        }
    }
}


struct HorizontalCategoryBarView: View {
    let categories: [CategoryStatistic]
    @Binding var selectedCategory: CategoryStatistic?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            GeometryReader { proxy in
                HStack(spacing: proxy.size.width * 0.015) {
                    ForEach(categories) { category in
                        if category.percentage >= 0.5 {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: category.categoryColorHex))
                                .frame(width: (proxy.size.width * (1.0 - (0.015 * Double(categories.count - 1)))) * (category.percentage / 100))
                                .opacity(selectedCategory == nil || selectedCategory?.id == category.id ? 1 : 0.5)
                                .overlay {
                                    if selectedCategory?.id == category.id {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(OGDesign.Colors.backgroundPrimary, lineWidth: 1.5)
                                    }
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        if selectedCategory?.id == category.id {
                                            selectedCategory = nil
                                        } else {
                                            selectedCategory = category
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
            
            // Category List
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(categories) { category in
                        CategoryListRow(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        ) {
                            withAnimation(.easeInOut) {
                                if selectedCategory?.id == category.id {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
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

// MARK: - Category List Row

struct CategoryListRow: View {
    let category: CategoryStatistic
    let isSelected: Bool
    let action: () -> Void
    
    private var boxColor: Color {
        Color(hex: category.categoryColorHex)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(category.categoryName)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(category.amount.formatted(currencyCode: "USD"))
                    .font(.system(isSelected ? .title3 : .body, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .lineLimit(1)
                    .layoutPriority(1)
                
                if isSelected {
                    Button {
                        action()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                            .padding(5)
                            .background(OGDesign.Colors.glassFill, in: Circle())
                    }
                } else {
                    Text("\(Int(category.percentage))%")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(boxColor)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(boxColor.opacity(0.23), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.vertical, isSelected ? 10 : 5)
            .padding(.horizontal, isSelected ? 10 : 0)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? OGDesign.Colors.glassFill : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? OGDesign.Colors.glassBorder : Color.clear, lineWidth: 1.3)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Week Graph Content View

struct WeekGraphContentView: View {
    let statistics: Statistics
    
    @State private var income = false
    @State private var incomeFiltering = true
    @State private var selectedDate: Date?
    @State private var selectedCategory: CategoryStatistic?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                SingleGraphView(
                    statistics: statistics,
                    chartType: 1,
                    income: $income,
                    incomeFiltering: $incomeFiltering,
                    selectedDate: $selectedDate
                )
                .padding(.horizontal, 30)
                .padding(.bottom, incomeFiltering ? 5 : 10)
                
                if incomeFiltering && selectedDate == nil {
                    HorizontalCategoryBarView(
                        categories: statistics.categoryBreakdown.filter { $0.type == (income ? .income : .expense) },
                        selectedCategory: $selectedCategory
                    )
                    .padding(.horizontal, 30)
                    .padding(.bottom, 70)
                }
            }
        }
    }
}

// MARK: - Month Graph Content View

struct MonthGraphContentView: View {
    let statistics: Statistics
    
    @State private var income = false
    @State private var incomeFiltering = true
    @State private var selectedDate: Date?
    @State private var selectedCategory: CategoryStatistic?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                SingleGraphView(
                    statistics: statistics,
                    chartType: 2,
                    income: $income,
                    incomeFiltering: $incomeFiltering,
                    selectedDate: $selectedDate
                )
                .padding(.horizontal, 30)
                .padding(.bottom, incomeFiltering ? 5 : 20)
                
                if incomeFiltering && selectedDate == nil {
                    HorizontalCategoryBarView(
                        categories: statistics.categoryBreakdown.filter { $0.type == (income ? .income : .expense) },
                        selectedCategory: $selectedCategory
                    )
                    .padding(.horizontal, 30)
                    .padding(.bottom, 70)
                }
            }
        }
    }
}

// MARK: - Year Graph Content View

struct YearGraphContentView: View {
    let statistics: Statistics
    
    @State private var income = false
    @State private var incomeFiltering = true
    @State private var selectedDate: Date?
    @State private var selectedCategory: CategoryStatistic?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                SingleGraphView(
                    statistics: statistics,
                    chartType: 3,
                    income: $income,
                    incomeFiltering: $incomeFiltering,
                    selectedDate: $selectedDate
                )
                .padding(.horizontal, 30)
                .padding(.bottom, incomeFiltering ? 5 : 20)
                
                if incomeFiltering && selectedDate == nil {
                    HorizontalCategoryBarView(
                        categories: statistics.categoryBreakdown.filter { $0.type == (income ? .income : .expense) },
                        selectedCategory: $selectedCategory
                    )
                    .padding(.horizontal, 30)
                    .padding(.bottom, 70)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .preferredColorScheme(.dark)
}
