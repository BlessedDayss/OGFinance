//
//  CategoryIconPicker.swift
//  OG Finance
//
//  Created by Orkhan Gojayev on 07/01/2026.
//

import SwiftUI

struct CategoryIconPicker: View {
    
    @Binding var selectedIcon: String
    let selectedColor: Color
    
    // Curated SF Symbols for finance apps
    private let icons = [
        "fork.knife", "cart.fill", "car.fill", "house.fill", 
        "tram.fill", "airplane", "gift.fill", "gamecontroller.fill",
        "desktopcomputer", "bag.fill", "tshirt.fill", "cross.case.fill",
        "pills.fill", "pawprint.fill", "leaf.fill", "flame.fill",
        "bolt.fill", "drop.fill", "wifi", "phone.fill",
        "film.fill", "ticket.fill", "music.note", "book.fill",
        "graduationcap.fill", "briefcase.fill", "banknote.fill", "chart.pie.fill",
        "star.fill", "heart.fill", "camera.fill", "hammer.fill",
        "wrench.and.screwdriver.fill", "paintpalette.fill", "scissors", "gym.bag.fill"
    ]
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 44))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(icons, id: \.self) { icon in
                let isSelected = selectedIcon == icon
                
                Circle()
                    .fill(isSelected ? selectedColor.opacity(0.2) : OGDesign.Colors.glassFill)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundStyle(isSelected ? selectedColor : OGDesign.Colors.textSecondary)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSelected ? selectedColor : OGDesign.Colors.glassBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                    .onTapGesture {
                        HapticManager.shared.selection_()
                        selectedIcon = icon
                    }
            }
        }
        .padding()
    }
}

#Preview {
    ZStack {
        OGDesign.Colors.backgroundPrimary.ignoresSafeArea()
        CategoryIconPicker(selectedIcon: .constant("fork.knife"), selectedColor: .blue)
    }
    .preferredColorScheme(.dark)
}
