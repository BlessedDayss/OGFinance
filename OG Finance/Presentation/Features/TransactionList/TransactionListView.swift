//
//  TransactionListView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

struct TransactionListView: View {
    
    @State private var transactions: [Transaction] = []
    @State private var isLoading = true
    @State private var filterType: TransactionType?
    @State private var searchMode = false
    @State private var searchQuery = ""
    @State private var showFilter = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var filteredTransactions: [Transaction] {
        var result = transactions
        
        if let filterType = filterType {
            result = result.filter { $0.type == filterType }
        }
        
        if !searchQuery.isEmpty {
            result = result.filter { transaction in
                transaction.note.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        return result
    }
    
    private var groupedTransactions: [(Date, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        if transactions.isEmpty && !isLoading {
            emptyStateView
        } else {
            mainContentView
        }
    }
    
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
            
            Text("Add your first transaction\nto get started")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(OGDesign.Colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 30)
        .frame(height: 250, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OGDesign.Colors.backgroundPrimary)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 25)
                .padding(.top, 10)
            
            if filterType != nil {
                filterTagView
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
            }
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(groupedTransactions, id: \.0) { date, dayTransactions in
                        TransactionDaySectionView(
                            date: date,
                            transactions: dayTransactions,
                            dayTotal: calculateDayTotal(dayTransactions),
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
                await loadTransactions()
            }
        }
        .background(OGDesign.Colors.backgroundPrimary)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $searchMode) {
            TransactionSearchView(transactions: transactions)
        }
        .task {
            await loadTransactions()
        }
    }
    
    private var headerBar: some View {
        HStack {
            Button {
                searchMode = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .padding(5)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            Text("Transactions")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            Spacer()
            
            Menu {
                Button {
                    withAnimation(.easeIn(duration: 0.15)) {
                        filterType = nil
                    }
                    HapticManager.shared.selection_()
                } label: {
                    Label("All", systemImage: filterType == nil ? "checkmark" : "")
                }
                
                Button {
                    withAnimation(.easeIn(duration: 0.15)) {
                        filterType = .income
                    }
                    HapticManager.shared.selection_()
                } label: {
                    Label("Income", systemImage: filterType == .income ? "checkmark" : "")
                }
                
                Button {
                    withAnimation(.easeIn(duration: 0.15)) {
                        filterType = .expense
                    }
                    HapticManager.shared.selection_()
                } label: {
                    Label("Expense", systemImage: filterType == .expense ? "checkmark" : "")
                }
            } label: {
                Image(systemName: filterType == nil ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(filterType == nil ? OGDesign.Colors.textSecondary : OGDesign.Colors.primary)
                    .padding(5)
                    .contentShape(Rectangle())
            }
        }
        .frame(height: 50)
    }
    
    private var filterTagView: some View {
        HStack(spacing: 10) {
            Text(filterType == .income ? "Income" : "Expense")
                .font(.system(.body, design: .rounded).weight(.medium))
            
            Button {
                withAnimation(.easeIn(duration: 0.15)) {
                    filterType = nil
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
    
    private func calculateDayTotal(_ transactions: [Transaction]) -> Decimal {
        transactions.reduce(Decimal.zero) { result, transaction in
            if transaction.type == .income {
                return result + transaction.amount
            } else {
                return result - transaction.amount
            }
        }
    }
    
    private func loadTransactions() async {
        isLoading = true
        
        do {
            transactions = try await DependencyContainer.shared.transactionRepository.fetchAll()
        } catch {
            print("Error loading transactions: \(error)")
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

struct TransactionDaySectionView: View {
    let date: Date
    let transactions: [Transaction]
    let dayTotal: Decimal
    let onDelete: (Transaction) -> Void
    
    private var dateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "TODAY")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "YESTERDAY")
        } else {
            let currentYear = calendar.component(.year, from: Date())
            let dateYear = calendar.component(.year, from: date)
            
            let formatter = DateFormatter()
            if dateYear < currentYear {
                formatter.dateFormat = "EEE, d MMM ''yy"
            } else {
                formatter.dateFormat = "EEE, d MMM"
            }
            return formatter.string(from: date).uppercased()
        }
    }
    
    private var totalString: String {
        dayTotal.formatted(currencyCode: "USD", showPositiveSign: true)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                HStack {
                    Text(dateText)
                    Spacer()
                    Text(totalString)
                        .layoutPriority(1)
                }
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                
                Rectangle()
                    .fill(OGDesign.Colors.glassBorder)
                    .frame(height: 1.3)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            ForEach(transactions) { transaction in
                TransactionRowView(
                    transaction: transaction,
                    onDelete: { onDelete(transaction) }
                )
            }
        }
        .padding(.bottom, 18)
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    let onDelete: () -> Void
    
    @State private var category: Category?
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
        let formatted = transaction.amount.formatted(currencyCode: "USD")
        return transaction.type == .income ? "+\(formatted)" : "-\(formatted)"
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
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
            
            HStack(spacing: 12) {
                TransactionEmojiBox(
                    emoji: category?.icon ?? "💰",
                    colorHex: category?.colorHex ?? "#7367F0"
                )
                .fixedSize(horizontal: true, vertical: true)
                
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
            .contextMenu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "xmark.bin")
                }
            }
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
        .task {
            category = try? await DependencyContainer.shared.categoryRepository.fetch(byId: transaction.categoryId)
        }
    }
}

struct TransactionEmojiBox: View {
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

struct TransactionSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    let transactions: [Transaction]
    @State private var searchQuery = ""
    @FocusState private var isFocused: Bool
    
    private var filteredTransactions: [Transaction] {
        guard !searchQuery.isEmpty else { return [] }
        
        return transactions.filter { transaction in
            transaction.note.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 9) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary.opacity(0.8))
                    
                    TextField("Search by note", text: $searchQuery)
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
                            TransactionRowView(
                                transaction: transaction,
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
