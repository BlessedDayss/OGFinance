//
//  AddTransactionView.swift
//  OG Finance
//
//  Created by OGTeam on 07/01/2026.
//

import SwiftUI
import CoreHaptics
import Combine

struct AddTransactionView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currency") private var currency = CurrencyManager.defaultCurrency
    
    // MARK: - State
    
    @State private var price: Double = 0
    @State private var note = ""
    @State private var date = Date.now
    @State private var income = false
    @State private var category: Category?
    @State private var categories: [Category] = []
    @State private var defaultAccountId: UUID?
    
    // Number entry
    @State private var isEditingDecimal = false
    @State private var decimalValuesAssigned: DecimalAssigned = .none
    
    // UI State
    @State private var showCategoryPicker = false
    @State private var showingDatePicker = false
    @State private var showCategorySheet = false
    @State private var noteFocused = false
    
    // Toast
    @State private var showToast = false
    @State private var toastTitle = ""
    @State private var toastImage = ""
    
    // Category button animation
    @State private var categoryButtonTextColor = OGDesign.Colors.textSecondary
    @State private var categoryButtonBackgroundColor = Color.clear
    @State private var categoryButtonOutlineColor = OGDesign.Colors.glassBorder
    @State private var shake: Bool = false
    
    // Swipe toggle
    @State private var swipingOffset: CGFloat = 0
    @GestureState private var isDragging = false
    
    // Haptics
    @State private var engine: CHHapticEngine?
    
    // Callbacks
    let onSave: () -> Void
    
    // MARK: - Computed
    
    private var capsuleWidth: CGFloat { 100 }
    
    private var filteredCategories: [Category] {
        categories.filter { category in
            if income {
                return category.applicableTypes.contains(.income)
            } else {
                return category.applicableTypes.contains(.expense)
            }
        }
    }
    
    private var amountString: String {
        if isEditingDecimal {
            switch decimalValuesAssigned {
            case .none:
                return String(format: "%.0f", price) + "."
            case .first:
                return String(format: "%.1f", price)
            case .second:
                return String(format: "%.2f", price)
            }
        }
        return String(format: "%.2f", price)
    }
    
    private var dateString: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "d MMM"
            return "Today, \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "E, d MMM"
            return formatter.string(from: date)
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Init
    
    init(onSave: @escaping () -> Void = {}) {
        self.onSave = onSave
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Top Bar with toggle and buttons
            topBar
            
            // Amount display area (swipeable)
            ZStack {
                OGDesign.Colors.backgroundPrimary
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .simultaneousGesture(swipeGesture)
                
                VStack(spacing: 8) {
                    amountDisplay
                    noteField
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Date and Category row
            dateAndCategoryRow
                .padding(.bottom, 5)
            
            // Number Pad or Category Picker
            if showCategoryPicker {
                categoryPickerGrid
                    .frame(height: 280)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                numberPadView
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .padding(17)
        .padding(.top, 40)
        .background(OGDesign.Colors.backgroundPrimary)
        .onTapGesture {
            hideKeyboard()
        }
        .ignoresSafeArea(.keyboard, edges: .all)
        .overlay(datePickerOverlay)
        .animation(.easeOut(duration: 0.2), value: showToast)
        .onChange(of: showToast) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .onChange(of: income) { _, _ in
            HapticManager.shared.light()
            category = nil
        }
        .onChange(of: isDragging) { _, newValue in
            if !newValue {
                if income {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        swipingOffset = capsuleWidth
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        swipingOffset = 0
                    }
                }
            }
        }
        .task {
            await loadCategories()
            prepareHaptics()
        }
        .sheet(isPresented: $showCategorySheet) {
            AddCategoryView()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        VStack {
            if showToast {
                toastView
                    .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
            } else {
                incomeExpenseToggle
            }
        }
        .frame(maxWidth: .infinity)
        .overlay {
            HStack {
                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .padding(7)
                        .background(OGDesign.Colors.glassFill, in: Circle())
                        .contentShape(Circle())
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Toast View
    
    private var toastView: some View {
        HStack(spacing: 6.5) {
            Image(systemName: toastImage)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.expense)
            
            Text(toastTitle)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(OGDesign.Colors.expense)
        }
        .padding(8)
        .background(
            OGDesign.Colors.expense.opacity(0.23),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .frame(maxWidth: 200)
    }
    
    // MARK: - Income/Expense Toggle
    
    private var incomeExpenseToggle: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(OGDesign.Colors.glassFill)
                .frame(width: capsuleWidth)
                .offset(x: swipingOffset)
            
            HStack(spacing: 0) {
                Text("Expense")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(income == false ? OGDesign.Colors.textPrimary : OGDesign.Colors.textSecondary)
                    .padding(6)
                    .frame(width: capsuleWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.15)) {
                            income = false
                            swipingOffset = 0
                        }
                    }
                
                Text("Income")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(income == true ? OGDesign.Colors.textPrimary : OGDesign.Colors.textSecondary)
                    .padding(6)
                    .frame(width: capsuleWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.15)) {
                            income = true
                            swipingOffset = capsuleWidth
                        }
                    }
            }
        }
        .padding(3)
        .fixedSize(horizontal: true, vertical: true)
        .overlay(Capsule().stroke(OGDesign.Colors.glassBorder.opacity(0.4), lineWidth: 1.3))
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { gesture in
                let swipe = gesture.translation.width
                
                if income {
                    if swipe < 0 {
                        swipingOffset = max(-capsuleWidth, -pow(abs(swipe), 0.8)) + capsuleWidth
                    }
                } else {
                    if swipe > 0 {
                        swipingOffset = min(capsuleWidth, pow(swipe, 0.8))
                    }
                }
            }
            .onEnded { _ in
                if income {
                    if swipingOffset < (capsuleWidth / 2) {
                        withAnimation {
                            swipingOffset = 0
                            income = false
                        }
                    } else {
                        withAnimation {
                            swipingOffset = capsuleWidth
                        }
                    }
                } else {
                    if swipingOffset > (capsuleWidth / 2) {
                        withAnimation {
                            swipingOffset = capsuleWidth
                            income = true
                        }
                    } else {
                        withAnimation {
                            swipingOffset = 0
                        }
                    }
                }
            }
    }
    
    // MARK: - Amount Display
    
    private var amountDisplay: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(CurrencyManager.symbol(for: currency))
                .font(.system(.largeTitle, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            Text(amountString)
                .font(.system(size: 50, weight: .regular, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textPrimary)
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            // Delete button
            Button {
                deleteLastDigit()
            } label: {
                Image(systemName: "delete.left.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(OGDesign.Colors.textSecondary)
                    .padding(7)
                    .background(OGDesign.Colors.glassFill, in: Circle())
                    .contentShape(Circle())
            }
            .disabled(price == 0 && !isEditingDecimal)
            .opacity(price == 0 && !isEditingDecimal ? 0.5 : 1)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Note Field
    
    private var noteField: some View {
        HStack(spacing: 7) {
            Image(systemName: "text.alignleft")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
            
            ZStack(alignment: .leading) {
                TextField("", text: $note)
                    .foregroundStyle(OGDesign.Colors.textPrimary)
                    .onReceive(note.publisher.collect()) { chars in
                        if chars.count > 50 {
                            note = String(chars.prefix(50))
                        }
                    }
                
                if note.isEmpty {
                    Text("Add Note")
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                }
            }
            .font(.system(.body, design: .rounded).weight(.semibold))
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                .stroke(OGDesign.Colors.glassBorder, lineWidth: 1.5)
        )
        .fixedSize(horizontal: true, vertical: false)
    }
    
    // MARK: - Date and Category Row
    
    private var dateAndCategoryRow: some View {
        HStack(spacing: 8) {
            // Date Button
            dateButton
            
            // Category Button
            categoryButton
        }
    }
    
    private var dateButton: some View {
        HStack(spacing: 7) {
            Image(systemName: date <= Date.now ? "calendar" : "rays")
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            
            Text(dateString)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .lineLimit(1)
            
            Spacer()
            
            Text(timeString)
                .font(.system(.body, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(OGDesign.Colors.textPrimary)
        .padding(.vertical, 8.5)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                .strokeBorder(OGDesign.Colors.glassBorder, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
            showingDatePicker = true
        }
    }
    
    @ViewBuilder
    private var categoryButton: some View {
        Group {
            if showCategoryPicker {
                // Close button
                HStack(spacing: 10) {
                    Text("Close")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                }
                .padding(.vertical, 8.5)
                .padding(.horizontal, 10)
                .foregroundStyle(OGDesign.Colors.expense)
                .background(
                    OGDesign.Colors.expense.opacity(0.23),
                    in: RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                )
            } else if let selectedCategory = category {
                // Selected category
                HStack(spacing: 5) {
                    categoryIcon(selectedCategory.icon)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                    
                    Text(selectedCategory.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                }
                .padding(.vertical, 8.5)
                .padding(.horizontal, 10)
                .foregroundStyle(Color(hex: selectedCategory.colorHex))
                .background(
                    Color(hex: selectedCategory.colorHex).opacity(0.35),
                    in: RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                )
            } else {
                // Category placeholder
                HStack(spacing: 5.5) {
                    Image(systemName: "circle.grid.2x2")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .symbolEffect(.bounce.up.byLayer, options: .repeating.speed(0.5), value: showCategoryPicker)
                    
                    Text("Category")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                }
                .padding(.vertical, 8.5)
                .padding(.horizontal, 10)
                .foregroundStyle(categoryButtonTextColor)
                .background(
                    categoryButtonBackgroundColor,
                    in: RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                        .strokeBorder(categoryButtonOutlineColor, lineWidth: 1.5)
                )
                .drawingGroup()
                .offset(x: shake ? -5 : 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut) {
                showCategoryPicker.toggle()
            }
        }
    }
    
    // MARK: - Date Picker Overlay
    
    private var datePickerOverlay: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { _ in
                EmptyView()
            }
            .background(Color.black)
            .opacity(showingDatePicker ? 0.3 : 0)
            .onTapGesture {
                showingDatePicker = false
            }
            
            DatePicker("Date", selection: $date)
                .datePickerStyle(.graphical)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
                .padding(17)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .opacity(showingDatePicker ? 1 : 0)
        .allowsHitTesting(showingDatePicker)
        .animation(.easeOut(duration: 0.25), value: showingDatePicker)
    }
    
    // MARK: - Category Picker Grid (like appDIME)
    
    private var categoryPickerGrid: some View {
        let layout = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible())
        ]
        
        return ScrollView(showsIndicators: false) {
            LazyVGrid(columns: layout, spacing: 10) {
                ForEach(filteredCategories) { item in
                    HStack(spacing: 7) {
                        // Check if icon is SF Symbol (contains ".") or emoji
                        categoryIcon(item.icon)
                            .font(.system(.title3, design: .rounded))
                        
                        Text(item.name)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .foregroundStyle(Color(hex: item.colorHex))
                    .background(
                        Color(hex: item.colorHex).opacity(0.35),
                        in: RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                    )
                    .contentShape(Rectangle())
                    .overlay {
                        if item.id == category?.id {
                            RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                                .strokeBorder(Color(hex: item.colorHex), lineWidth: 2)
                        }
                    }
                    .onTapGesture {
                        withAnimation {
                            category = item
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                showCategoryPicker = false
                            }
                        }
                    }
                    .opacity(category != nil ? (category?.id == item.id ? 1 : 0.5) : 1)
                }
            }
        }
        .overlay(alignment: .bottom) {
            // Edit button at bottom (like appDIME)
            HStack(spacing: 4) {
                Image(systemName: "pencil")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                Text("Edit")
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 18)
            .foregroundStyle(OGDesign.Colors.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                    .fill(OGDesign.Colors.glassFill)
                    .shadow(color: Color.black.opacity(0.2), radius: 6)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.shared.light()
                showCategoryPicker = false
                showCategorySheet = true
            }
            .padding(.bottom, 15)
        }
        .padding(.bottom, 15)
    }
    
    // MARK: - Number Pad View (like appDIME with fixed sizes)
    
    private var numberPadView: some View {
        let numPadNumbers = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
        
        return VStack(spacing: 10) {
            ForEach(numPadNumbers, id: \.self) { array in
                HStack(spacing: 10) {
                    ForEach(array, id: \.self) { number in
                        numberButton(number: number)
                    }
                }
            }
            
            // Bottom row: delete, 0, submit
            HStack(spacing: 10) {
                // Delete button
                Button {
                    deleteLastDigit()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 24, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(OGDesign.Colors.backgroundSecondary)
                        .foregroundStyle(OGDesign.Colors.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(NumPadButtonStyle())
                
                // Zero button
                numberButton(number: 0)
                
                // Submit button
                Button {
                    submit()
                } label: {
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .symbolEffect(.bounce.up.byLayer, value: price != 0 && category != nil)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .foregroundStyle(OGDesign.Colors.textPrimary)
                        .background(
                            OGDesign.Colors.backgroundSecondary,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
                .buttonStyle(NumPadButtonStyle())
            }
        }
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func numberButton(number: Int) -> some View {
        let disabled = price >= 100000000
        
        Button {
            if disabled { return }
            
            hapticTap()
            
            // Standard entry (cents first)
            price *= 10
            price += Double(number) / 100
        } label: {
            Text("\(number)")
                .font(.system(size: 34, weight: .regular, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(OGDesign.Colors.glassFill)
                .foregroundStyle(OGDesign.Colors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .opacity(disabled ? 0.6 : 1)
        }
        .disabled(disabled)
        .buttonStyle(NumPadButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func deleteLastDigit() {
        price = Double(Int(price * 10)) / 100
    }
    
    private func toggleFieldColors() {
        if categoryButtonTextColor == OGDesign.Colors.expense {
            withAnimation(.linear) {
                categoryButtonTextColor = OGDesign.Colors.textSecondary
                categoryButtonBackgroundColor = Color.clear
                categoryButtonOutlineColor = OGDesign.Colors.glassBorder
            }
        } else {
            withAnimation(.easeOut(duration: 1.0)) {
                categoryButtonTextColor = OGDesign.Colors.expense
                categoryButtonBackgroundColor = OGDesign.Colors.expense.opacity(0.23)
                categoryButtonOutlineColor = OGDesign.Colors.expense
            }
            withAnimation(.easeInOut(duration: 0.1).repeatCount(5)) {
                shake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    shake = false
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    categoryButtonTextColor = OGDesign.Colors.textSecondary
                    categoryButtonBackgroundColor = Color.clear
                    categoryButtonOutlineColor = OGDesign.Colors.glassBorder
                }
            }
        }
    }
    
    private func submit() {
        if price == 0 && category == nil {
            toastImage = "questionmark.app"
            toastTitle = "Incomplete Entry"
            showToast = true
            toggleFieldColors()
            HapticManager.shared.error()
            return
        } else if price == 0 {
            toastImage = "centsign.circle"
            toastTitle = "Missing Amount"
            showToast = true
            HapticManager.shared.error()
            return
        } else if category == nil {
            toastImage = "tray"
            toastTitle = "Missing Category"
            showToast = true
            toggleFieldColors()
            HapticManager.shared.error()
            return
        }
        
        HapticManager.shared.success()
        
        // Save transaction
        Task {
            do {
                let finalNote = note.trimmingCharacters(in: .whitespaces).isEmpty 
                    ? (category?.name ?? "") 
                    : note.trimmingCharacters(in: .whitespaces)
                
                // Ensure we have a valid account ID
                guard let accountId = defaultAccountId else {
                    print("❌ Save Failed: No default account ID")
                    throw TransactionError.accountNotFound
                }
                
                print("💾 Saving transaction: amount=\(price), type=\(income ? "income" : "expense"), categoryId=\(category!.id), accountId=\(accountId)")
                
                try await DependencyContainer.shared.makeAddTransactionUseCase().execute(
                    amount: Decimal(price),
                    type: income ? .income : .expense,
                    categoryId: category!.id,
                    accountId: accountId,
                    date: date,
                    note: finalNote
                )
                
                print("✅ Transaction saved successfully!")

                await MainActor.run {
                    // Post notification with amount & type for INSTANT balance update
                    TransactionNotificationCenter.shared.postTransactionAdded(
                        amount: Decimal(price),
                        type: income ? .income : .expense
                    )
                    
                    onSave()
                    dismiss()
                }
            } catch {
                print("❌ Save Failed: \(error)")
                await MainActor.run {
                    toastImage = "exclamationmark.triangle"
                    toastTitle = "Save Failed"
                    showToast = true
                }
            }
        }
    }
    
    private func loadCategories() async {
        do {
            categories = try await DependencyContainer.shared.categoryRepository.fetchAll()
            
            // Debug: print loaded categories
            print("📂 Loaded \(categories.count) categories:")
            for cat in categories {
                print("   - \(cat.name): icon='\(cat.icon)', types=\(cat.applicableTypes)")
            }
            
            // If no categories loaded, use defaults
            if categories.isEmpty {
                print("⚠️ No categories in DB, using defaults")
                categories = Category.allDefaults
            }
        } catch {
            print("❌ Error loading categories: \(error)")
            // Fallback to defaults
            categories = Category.allDefaults
        }
        
        // Load default account
        do {
            let accounts = try await DependencyContainer.shared.accountRepository.fetchAll()
            print("🏦 Loaded \(accounts.count) accounts")
            for acc in accounts {
                print("   - \(acc.name): id=\(acc.id), isDefault=\(acc.isDefault)")
            }
            
            // Use existing account (prefer default, otherwise first)
            if let existingAccount = accounts.first(where: { $0.isDefault }) ?? accounts.first {
                defaultAccountId = existingAccount.id
                print("✅ Using existing account ID: \(existingAccount.id)")
            } else {
                // No account exists - create one
                print("⚠️ No account found, creating default")
                let newAccount = Account(
                    name: "Main Account",
                    type: .checking,
                    balance: 0,
                    currencyCode: "USD",
                    colorHex: "007AFF",
                    sortOrder: 0,
                    isDefault: true,
                    includeInTotal: true
                )
                try await DependencyContainer.shared.accountRepository.add(newAccount)
                defaultAccountId = newAccount.id
                print("✅ Created new account ID: \(newAccount.id)")
            }
        } catch {
            print("❌ Error loading accounts: \(error)")
            // Last resort - create a new account
            let fallbackAccount = Account(
                name: "Main Account",
                type: .checking,
                isDefault: true
            )
            defaultAccountId = fallbackAccount.id
        }
    }
    
    // Helper to render category icon (handles both SF Symbols and emojis)
    @ViewBuilder
    private func categoryIcon(_ icon: String) -> some View {
        // Check if first character is emoji
        let isEmoji = icon.unicodeScalars.first?.properties.isEmoji == true && 
                      icon.unicodeScalars.first?.properties.isEmojiPresentation == true
        
        if isEmoji || icon.count <= 2 {
            // It's an emoji - display as text
            Text(icon)
                .font(.system(size: 20))
        } else if UIImage(systemName: icon) != nil {
            // It's a valid SF Symbol
            Image(systemName: icon)
        } else {
            // Fallback - try as text
            Text(icon)
                .font(.system(size: 20))
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Haptics
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics error: \(error.localizedDescription)")
        }
    }
    
    private func hapticTap() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let hapticDict: [CHHapticPattern.Key: Any] = [
            .pattern: [
                [CHHapticPattern.Key.event: [
                    CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                    CHHapticPattern.Key.time: CHHapticTimeImmediate,
                    CHHapticPattern.Key.eventDuration: 1.0
                ]]
            ]
        ]
        
        do {
            let pattern = try CHHapticPattern(dictionary: hapticDict)
            let player = try engine?.makePlayer(with: pattern)
            
            engine?.notifyWhenPlayersFinished { _ in
                return .stopEngine
            }
            
            try engine?.start()
            try player?.start(atTime: 0)
        } catch {
            print("Haptic error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Decimal Assigned Enum

enum DecimalAssigned {
    case none, first, second
}

// MARK: - NumPad Button Style

struct NumPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Preview

#Preview {
    AddTransactionView()
        .preferredColorScheme(.dark)
}
