//
//  Decimal+Currency.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import Foundation

extension Decimal {
    
    /// Format as currency string
    /// - Parameters:
    ///   - currencyCode: ISO 4217 currency code (default: USD)
    ///   - showPositiveSign: Whether to show + for positive values
    /// - Returns: Formatted currency string
    func formatted(
        currencyCode: String = "USD",
        showPositiveSign: Bool = false
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        if showPositiveSign && self > 0 {
            formatter.positivePrefix = "+"
        }
        
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
    
    /// Format as compact currency (e.g., $1.2K, $3.5M)
    /// - Parameter currencyCode: ISO 4217 currency code
    /// - Returns: Compact formatted string
    func formattedCompact(currencyCode: String = "USD") -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        
        let symbol = currencySymbol(for: currencyCode)
        
        switch absValue {
        case 1_000_000_000...:
            let value = absValue / 1_000_000_000
            return "\(sign)\(symbol)\(value.rounded(to: 1))B"
        case 1_000_000...:
            let value = absValue / 1_000_000
            return "\(sign)\(symbol)\(value.rounded(to: 1))M"
        case 1_000...:
            let value = absValue / 1_000
            return "\(sign)\(symbol)\(value.rounded(to: 1))K"
        default:
            return formatted(currencyCode: currencyCode)
        }
    }
    
    /// Round to specified decimal places
    private func rounded(to places: Int) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = places
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .halfUp
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
    
    /// Get currency symbol for code
    private func currencySymbol(for code: String) -> String {
        let locale = Locale.availableIdentifiers
            .map { Locale(identifier: $0) }
            .first { $0.currency?.identifier == code }
        
        return locale?.currencySymbol ?? code
    }
}

// MARK: - Parsing

extension Decimal {
    
    /// Parse a string to Decimal, handling various formats
    /// - Parameter string: Input string (e.g., "1,234.56" or "1234.56")
    /// - Returns: Parsed Decimal or nil
    static func parse(_ string: String) -> Decimal? {
        // Remove currency symbols and whitespace
        var cleaned = string
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common currency symbols
        let currencySymbols = ["$", "€", "£", "¥", "₽", "₴"]
        for symbol in currencySymbols {
            cleaned = cleaned.replacingOccurrences(of: symbol, with: "")
        }
        
        // Handle comma as thousands separator
        if cleaned.contains(",") && cleaned.contains(".") {
            // Format: 1,234.56
            cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        } else if cleaned.contains(",") {
            // Could be European format (1.234,56) or thousands (1,234)
            let parts = cleaned.components(separatedBy: ",")
            if parts.count == 2 && parts.last?.count == 2 {
                // European format: 1.234,56
                cleaned = cleaned
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
            } else {
                // Thousands separator
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        }
        
        return Decimal(string: cleaned)
    }
}
