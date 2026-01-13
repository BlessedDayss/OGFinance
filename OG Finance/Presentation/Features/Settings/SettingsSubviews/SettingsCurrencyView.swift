//
//  SettingsCurrencyView.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 13/01/2026.
//

import SwiftUI

struct SettingsCurrencyView: View {
    
    // MARK: - Properties
    
    @AppStorage("currency") var currency: String = Locale.current.currency?.identifier ?? "USD"
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation
    
    // Common currencies
    private let currencies: [(code: String, name: String, symbol: String)] = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("JPY", "Japanese Yen", "¥"),
        ("CNY", "Chinese Yuan", "¥"),
        ("AUD", "Australian Dollar", "A$"),
        ("CAD", "Canadian Dollar", "C$"),
        ("CHF", "Swiss Franc", "Fr"),
        ("HKD", "Hong Kong Dollar", "HK$"),
        ("SGD", "Singapore Dollar", "S$"),
        ("SEK", "Swedish Krona", "kr"),
        ("KRW", "South Korean Won", "₩"),
        ("NOK", "Norwegian Krone", "kr"),
        ("NZD", "New Zealand Dollar", "NZ$"),
        ("INR", "Indian Rupee", "₹"),
        ("MXN", "Mexican Peso", "$"),
        ("TWD", "Taiwan Dollar", "NT$"),
        ("ZAR", "South African Rand", "R"),
        ("BRL", "Brazilian Real", "R$"),
        ("DKK", "Danish Krone", "kr"),
        ("PLN", "Polish Zloty", "zł"),
        ("THB", "Thai Baht", "฿"),
        ("ILS", "Israeli Shekel", "₪"),
        ("IDR", "Indonesian Rupiah", "Rp"),
        ("CZK", "Czech Koruna", "Kč"),
        ("AED", "UAE Dirham", "د.إ"),
        ("TRY", "Turkish Lira", "₺"),
        ("HUF", "Hungarian Forint", "Ft"),
        ("CLP", "Chilean Peso", "$"),
        ("SAR", "Saudi Riyal", "﷼"),
        ("PHP", "Philippine Peso", "₱"),
        ("MYR", "Malaysian Ringgit", "RM"),
        ("COP", "Colombian Peso", "$"),
        ("RON", "Romanian Leu", "lei"),
        ("PEN", "Peruvian Sol", "S/"),
        ("AZN", "Azerbaijani Manat", "₼"),
        ("GEL", "Georgian Lari", "₾"),
        ("UAH", "Ukrainian Hryvnia", "₴"),
        ("KZT", "Kazakhstani Tenge", "₸")
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: OGDesign.Spacing.md) {
            // Header
            header
            
            // Currency List
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(currencies, id: \.code) { curr in
                            currencyRow(
                                code: curr.code,
                                name: curr.name,
                                symbol: curr.symbol,
                                isSelected: currency == curr.code,
                                isLast: curr.code == currencies.last?.code
                            ) {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    currency = curr.code
                                }
                                HapticManager.shared.selection_()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                            .id(curr.code)
                        }
                    }
                    .glassCard(cornerRadius: OGDesign.Radius.md, padding: OGDesign.Spacing.sm)
                    .padding(.bottom, OGDesign.Spacing.xxl)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(currency, anchor: .center)
                        }
                    }
                }
            }
        }
        .modifier(SettingsSubviewModifier())
    }
    
    // MARK: - Header
    
    private var header: some View {
        Text("Currency")
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundStyle(OGDesign.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    dismiss()
                } label: {
                    SettingsBackButton()
                }
            }
            .padding(.bottom, OGDesign.Spacing.md)
    }
    
    // MARK: - Currency Row
    
    @ViewBuilder
    private func currencyRow(
        code: String,
        name: String,
        symbol: String,
        isSelected: Bool,
        isLast: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: OGDesign.Spacing.sm) {
            Text(code)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(OGDesign.Colors.textSecondary)
                .frame(width: 45, alignment: .leading)
            
            Text(name)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Text(symbol)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OGDesign.Colors.textTertiary)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(OGDesign.Colors.primary)
                    .matchedGeometryEffect(id: "currencyCheck", in: animation)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, OGDesign.Spacing.sm)
        .padding(.horizontal, OGDesign.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .background(OGDesign.Colors.glassBorder)
            }
        }
    }
}

#Preview {
    SettingsCurrencyView()
        .preferredColorScheme(.dark)
}
