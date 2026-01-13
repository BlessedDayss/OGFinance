//
//  CategoryColorPicker.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

struct CategoryColorPicker: View {
    
    @Binding var selectedColorHex: String
        private let colors = [
        "FF6B6B", "4ECDC4", "45B7D1", "96CEB4", "FFEEAD",
        "D4A5A5", "9B59B6", "3498DB", "E67E22", "E74C3C",
        "2ECC71", "1ABC9C", "F1C40F", "34495E", "95A5A6",
        "ECF0F1", "8E44AD", "2C3E50", "F39C12", "D35400"
    ]
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 44))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(colors, id: \.self) { hex in
                let color = Color(hex: hex)
                let isSelected = selectedColorHex.uppercased() == hex.uppercased()
                
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    }
                    .shadow(color: color.opacity(0.4), radius: isSelected ? 8 : 4, x: 0, y: 4)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(OGDesign.Animation.springQuick, value: isSelected)
                    .onTapGesture {
                        HapticManager.shared.selection_()
                        selectedColorHex = hex
                    }
            }
        }
        .padding()
    }
}

#Preview {
    ZStack {
        OGDesign.Colors.backgroundPrimary.ignoresSafeArea()
        CategoryColorPicker(selectedColorHex: .constant("FF6B6B"))
    }
    .preferredColorScheme(.dark)
}
