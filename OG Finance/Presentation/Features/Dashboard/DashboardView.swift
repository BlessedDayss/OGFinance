//
//  DashboardView.swift
//  OG Finance
//
//

import SwiftUI

// MARK: - Shimmer Effect Modifier

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let bounce: Bool
    
    init(duration: Double = 2.0, bounce: Bool = true) {
        self.duration = duration
        self.bounce = bounce
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: phase * geometry.size.width * 1.5 - geometry.size.width * 0.25)
                    .blendMode(.overlay)
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 2.0, bounce: Bool = true) -> some View {
        modifier(ShimmerEffect(duration: duration, bounce: bounce))
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius / 2, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius, y: 0)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Animated Mesh Gradient Background

struct AnimatedMeshBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [animateGradient ? 0.6 : 0.4, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: [
                OGDesign.Colors.backgroundPrimary,
                OGDesign.Colors.backgroundSecondary,
                OGDesign.Colors.backgroundPrimary,
                OGDesign.Colors.backgroundSecondary,
                OGDesign.Colors.primary.opacity(0.1),
                OGDesign.Colors.backgroundSecondary,
                OGDesign.Colors.backgroundPrimary,
                OGDesign.Colors.backgroundSecondary,
                OGDesign.Colors.backgroundPrimary
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct DashboardView: View {
    
    // MARK: - ViewModel
    
    @State private var viewModel = DashboardViewModel()
    
    // MARK: - Currency
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    
    // MARK: - State
    
    @State private var showAddTransaction = false
    @State private var selectedTransactionType: TransactionType = .expense
    @State private var hasAppeared = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                AnimatedMeshBackground()
                
                if viewModel.recentTransactions.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
        }
        .fullScreenCover(isPresented: $showAddTransaction) {
            AddTransactionView(
                onSave: {
                    Task { await viewModel.refresh() }
                }
            )
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
        VStack(spacing: 20) {
            // Animated icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [OGDesign.Colors.primary.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "tray.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [OGDesign.Colors.textTertiary, OGDesign.Colors.textTertiary.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shimmer(duration: 3.0)
            }
            
            VStack(spacing: 8) {
                Text("Your Log is Empty")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Tap the + button to add\nyour first transaction")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            QuickActionButton(
                icon: "plus",
                title: "Income",
                color: OGDesign.Colors.income
            ) {
                selectedTransactionType = .income
                showAddTransaction = true
            }
            
            // Add Expense Button  
            QuickActionButton(
                icon: "minus",
                title: "Expense",
                color: OGDesign.Colors.expense
            ) {
                selectedTransactionType = .expense
                showAddTransaction = true
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
    @Bindable var viewModel: DashboardViewModel
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    @State private var showPeriodMenu = false
    @State private var insightsType = 1 // 1: net, 2: income, 3: expense
    
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
        case 1: return viewModel.periodNetChange
        case 2: return viewModel.periodIncome
        case 3: return viewModel.periodExpenses
        default: return viewModel.periodNetChange
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
                        Text(viewModel.timeFrame.displayName.lowercased())
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
                    isPositive: viewModel.isPositivePeriod,
                    currencyCode: currency
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
            if viewModel.periodIncome != 0 && viewModel.periodExpenses != 0 && insightsType == 1 {
                HStack(spacing: 8) {
                    Text("+\(viewModel.periodIncome.formatted(currencyCode: currency))")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(OGDesign.Colors.income)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    // Dotted separator
                    DottedSeparator()
                        .frame(width: 2, height: 15)
                        .foregroundStyle(OGDesign.Colors.glassBorder)
                    
                    Text("-\(viewModel.periodExpenses.formatted(currencyCode: currency))")
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
            ForEach(StatisticsPeriod.allCases.filter { $0 != .quarter && $0 != .allTime }, id: \.self) { period in
                Button(period.displayName) {
                    Task { await viewModel.changePeriod(period) }
                    HapticManager.shared.selection_()
                }
            }
        }
    }
}


// MARK: - Quick Action Button Component

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.medium))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.12))
                    
                    // Subtle glow border
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            }
        }
        .buttonStyle(QuickActionButtonStyle())
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AmountDisplayView: View {
    let amount: Decimal
    let isNetTotal: Bool
    let isPositive: Bool
    let currencyCode: String
    
    @State private var hasAppeared = false
    
    private var currencySymbol: String {
        CurrencyManager.symbol(for: currencyCode)
    }
    
    private var signedSymbol: String {
        if isNetTotal {
            return isPositive ? "+\(currencySymbol)" : "-\(currencySymbol)"
        }
        return currencySymbol
    }
    
    private var amountColor: Color {
        if isNetTotal {
            return isPositive ? OGDesign.Colors.income : OGDesign.Colors.expense
        }
        return OGDesign.Colors.textPrimary
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
        .shimmer(duration: 4.0)
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
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    
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
        let formatted = dayTotal.formatted(currencyCode: currency, showPositiveSign: true)
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
    
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    @State private var category: Category?
    @State private var offset: CGFloat = 0
    @GestureState private var isDragging = false
    
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

            Text(emoji)
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
