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
        HStack(alignment: .center) {
            Text("Transactions")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    searchMode = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .padding(10)
                        .background(OGDesign.Colors.glassFill.opacity(0.5), in: Circle())
                }
                
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
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(filterType == nil ? OGDesign.Colors.textSecondary : OGDesign.Colors.primary)
                        .padding(10)
                        .background(OGDesign.Colors.glassFill.opacity(0.5), in: Circle())
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
    }
    
    private var filterTagView: some View {
        HStack(spacing: 10) {
            Text(filterType == .income ? "Income" : "Expense")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
            
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
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(OGDesign.Colors.glassFill, in: Capsule())
        .overlay(Capsule().strokeBorder(OGDesign.Colors.glassBorder, lineWidth: 1))
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
            return String(localized: "Today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMMM"
            return formatter.string(from: date)
        }
    }
    
    private var totalString: String {
        dayTotal.formatted(currencyCode: "USD", showPositiveSign: true)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text(dateText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                
                Spacer()
                
                Text(totalString)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 12)
            
            // Rows
            VStack(spacing: 0) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    TransactionRowView(
                        transaction: transaction,
                        showDivider: index < transactions.count - 1,
                        onDelete: { onDelete(transaction) }
                    )
                }
            }
            .background(OGDesign.Colors.glassFill)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(OGDesign.Colors.glassBorder.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    let showDivider: Bool
    let onDelete: () -> Void
    
    @State private var category: Category?
    @State private var offset: CGFloat = 0
    @State private var deleted: Bool = false
    @GestureState private var isDragging = false
    
    private var deletePopup: Bool {
        abs(offset) > 60
    }
    
    private var deleteConfirm: Bool {
        abs(offset) > 120
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: transaction.date)
    }
    
    private var amountString: String {
        let formatted = transaction.amount.formatted(currencyCode: "USD")
        return transaction.type == .income ? "+\(formatted)" : "-\(formatted)"
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe Actions Background
            Color.red
                .opacity(deleteConfirm ? 1 : (abs(Double(offset)) / 120.0))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.vertical, 1) // Tiny padding to fix bleeding
            
            Image(systemName: "trash.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .padding(.trailing, 30)
                .scaleEffect(deleteConfirm ? 1.2 : 1.0)
                .opacity(deletePopup ? 1 : 0)
                .offset(x: 10 + offset * 0.1) // Parallax
            
            // Main Content
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Category Icon
                    TransactionEmojiBox(
                        emoji: category?.icon ?? "💰",
                        colorHex: category?.colorHex ?? "#7367F0"
                    )
                    
                    // Note & Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.note.isEmpty ? (category?.name ?? "Transaction") : transaction.note)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(OGDesign.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Text(transaction.note.isEmpty ? timeString : "\(category?.name ?? "General") • \(timeString)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(OGDesign.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Amount
                    Text(amountString)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(transaction.type == .income ? OGDesign.Colors.income : OGDesign.Colors.textPrimary)
                        .layoutPriority(1)
                }
                .padding(16)
                .background(OGDesign.Colors.glassFill) // Opaque-ish background against red
                
                if showDivider {
                    Rectangle()
                        .fill(OGDesign.Colors.glassBorder.opacity(0.5))
                        .frame(height: 1)
                        .padding(.leading, 76)
                }
            }
            .contentShape(Rectangle())
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in state = true }
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { _ in
                        if deleteConfirm {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = -UIScreen.main.bounds.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDelete()
                            }
                        } else {
                            withAnimation(.spring) {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16)) // Ensure content doesn't spill
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: colorHex).opacity(0.2))
            
            Text(emoji)
                .font(.system(size: 22))
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
                                showDivider: false,
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
