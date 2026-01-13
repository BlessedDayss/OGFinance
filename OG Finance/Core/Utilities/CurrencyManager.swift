//
//  CurrencyManager.swift
//  OG Finance
//
//  Created by OGTeam on 13/01/2026.
//

import Foundation
import SwiftUI

/// Global currency manager that provides access to the selected currency
/// across all views in the app.
///
/// Usage:
/// ```swift
/// @AppStorage("currency") var currency = CurrencyManager.defaultCurrency
/// // or
/// let symbol = CurrencyManager.symbol(for: "PLN") // "zł"
/// ```
enum CurrencyManager {
    
    // MARK: - Default
    
    /// Default currency code (based on locale or USD)
    static var defaultCurrency: String {
        Locale.current.currency?.identifier ?? "USD"
    }
    
    // MARK: - Currency Data
    
    /// All supported currencies with their symbols
    static let currencies: [String: String] = [
        "USD": "$",
        "EUR": "€",
        "GBP": "£",
        "JPY": "¥",
        "CNY": "¥",
        "AUD": "A$",
        "CAD": "C$",
        "CHF": "Fr",
        "HKD": "HK$",
        "SGD": "S$",
        "SEK": "kr",
        "KRW": "₩",
        "NOK": "kr",
        "NZD": "NZ$",
        "INR": "₹",
        "MXN": "$",
        "TWD": "NT$",
        "ZAR": "R",
        "BRL": "R$",
        "DKK": "kr",
        "PLN": "zł",
        "THB": "฿",
        "ILS": "₪",
        "IDR": "Rp",
        "CZK": "Kč",
        "AED": "د.إ",
        "TRY": "₺",
        "HUF": "Ft",
        "CLP": "$",
        "SAR": "﷼",
        "PHP": "₱",
        "MYR": "RM",
        "COP": "$",
        "RUB": "₽",
        "RON": "lei",
        "PEN": "S/",
        "AZN": "₼",
        "GEL": "₾",
        "UAH": "₴",
        "KZT": "₸"
    ]
    
    // MARK: - Methods
    
    /// Get currency symbol for a given code
    /// - Parameter code: ISO 4217 currency code (e.g., "USD", "PLN")
    /// - Returns: Currency symbol (e.g., "$", "zł")
    static func symbol(for code: String) -> String {
        currencies[code] ?? code
    }
    
    /// Get currency from UserDefaults
    static var current: String {
        UserDefaults.standard.string(forKey: "currency") ?? defaultCurrency
    }
    
    /// Get current currency symbol
    static var currentSymbol: String {
        symbol(for: current)
    }
}

// MARK: - View Extension for Easy Access

extension View {
    
    /// Access the current currency code from AppStorage
    var appCurrency: String {
        UserDefaults.standard.string(forKey: "currency") ?? CurrencyManager.defaultCurrency
    }
    
    /// Access the current currency symbol
    var appCurrencySymbol: String {
        CurrencyManager.symbol(for: appCurrency)
    }
}

// MARK: - Decimal Extension Update

extension Decimal {
    
    /// Format using the app's selected currency
    func formattedWithAppCurrency(showPositiveSign: Bool = false) -> String {
        formatted(currencyCode: CurrencyManager.current, showPositiveSign: showPositiveSign)
    }
    
    /// Format compact using the app's selected currency
    func formattedCompactWithAppCurrency() -> String {
        formattedCompact(currencyCode: CurrencyManager.current)
    }
}
