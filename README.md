<div align="center">

# 💎 OG Finance

### _Elegant Personal Finance Tracking for iOS_

<br>

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/ios)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Liquid_Glass-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-GPL%20v3-7367F0?style=for-the-badge)](LICENSE)

<br>

**Track expenses. Visualize insights. Master your money.**

<br>

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Architecture](#-architecture) • [Contributing](#-contributing)

<br>

---

<br>

</div>

## ✨ Features

<table>
<tr>
<td width="50%">

### 📊 **Smart Dashboard**
Real-time overview of your financial health with beautiful insights cards showing income, expenses, and net balance at a glance.

### 📈 **Advanced Analytics**
Interactive charts and statistics that help you understand your spending patterns with weekly, monthly, and yearly breakdowns.

### 🏷️ **Custom Categories**
Create personalized categories with custom icons and colors to organize your transactions exactly the way you want.

</td>
<td width="50%">

### 💰 **Transaction Tracking**
Effortlessly log income and expenses with a beautiful, intuitive interface designed for speed and simplicity.

### 🎨 **Liquid Glass Design**
Stunning dark theme with frosted glass effects, smooth animations, and a premium feel inspired by iOS 26.

### ⚡ **Haptic Feedback**
Tactile responses throughout the app for a more immersive and satisfying user experience.

</td>
</tr>
</table>

<br>

## 📱 Screenshots

<div align="center">

> _Screenshots coming soon — beautiful Liquid Glass UI awaits!_

<!-- 
<img src="assets/screenshots/dashboard.png" width="200" alt="Dashboard"/>
<img src="assets/screenshots/insights.png" width="200" alt="Insights"/>
<img src="assets/screenshots/add-transaction.png" width="200" alt="Add Transaction"/>
<img src="assets/screenshots/categories.png" width="200" alt="Categories"/>
-->

</div>

<br>

## 🎨 Design System

OG Finance features a custom **Liquid Glass** design system built from the ground up:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   🎨 Color Palette                                      │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━       │
│                                                         │
│   Primary      ████████  #7367F0                        │
│   Income       ████████  #28C76F                        │
│   Expense      ████████  #EA5455                        │
│   Warning      ████████  #FF9F43                        │
│                                                         │
│   Background   ████████  #0F1520                        │
│   Surface      ████████  #161D29                        │
│   Card         ████████  #1D2536                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Key Design Elements

| Element | Implementation |
|---------|---------------|
| **Glass Cards** | Multi-layered backgrounds with blur materials and gradient borders |
| **Floating Tab Bar** | Glassmorphism with inner glow and shadow depth |
| **Animations** | Spring physics for natural, bouncy interactions |
| **Typography** | SF Rounded for a modern, friendly feel |

<br>

## 🛠️ Installation

### Requirements

- **Xcode** 16.0 or later
- **iOS** 26.0 or later
- **Swift** 6.0 or later

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/BlessedDayss/OGFinance.git
   ```

2. **Navigate to the project**
   ```bash
   cd OGFinance
   ```

3. **Open in Xcode**
   ```bash
   open "OG Finance.xcodeproj"
   ```

4. **Build and run** on your simulator or device ▶️

<br>

## 🏗️ Architecture

OG Finance follows **Clean Architecture** principles with clear separation of concerns:

```
📦 OG Finance
├── 📁 App
│   ├── DependencyContainer      # Dependency injection
│   └── AppIntents               # Siri shortcuts support
│
├── 📁 Domain
│   ├── 📁 Entities              # Business models
│   ├── 📁 Repositories          # Repository protocols
│   └── 📁 UseCases              # Business logic
│
├── 📁 Data
│   ├── 📁 Models                # Data transfer objects
│   └── 📁 Repositories          # Repository implementations
│
├── 📁 Presentation
│   ├── 📁 DesignSystem          # Liquid Glass components
│   ├── 📁 Features              # Feature modules
│   │   ├── Dashboard
│   │   ├── Statistics
│   │   ├── AddTransaction
│   │   ├── TransactionList
│   │   ├── Category
│   │   └── Settings
│   └── 📁 Navigation            # Navigation flow
│
└── 📁 Core
    ├── 📁 Extensions            # Swift extensions
    └── 📁 Utilities             # Helper utilities
```

### Key Patterns

| Pattern | Usage |
|---------|-------|
| **MVVM** | View-ViewModel separation for UI logic |
| **Repository** | Abstract data access layer |
| **Use Cases** | Encapsulated business operations |
| **Dependency Injection** | Testable, modular components |

<br>

## 🗺️ Roadmap

<table>
<tr>
<td>

### In Progress 🚧
- [ ] iCloud Sync
- [ ] Budgets & Goals
- [ ] Recurring Transactions

</td>
<td>

### Planned 📋
- [ ] Widgets (Home & Lock Screen)
- [ ] Apple Watch App
- [ ] Data Export (CSV/PDF)

</td>
<td>

### Future 🔮
- [ ] Multiple Currencies
- [ ] AI-Powered Insights
- [ ] Collaborative Budgets

</td>
</tr>
</table>

<br>

## 🤝 Contributing

Contributions are what make the open-source community amazing! Any contributions you make are **greatly appreciated**.

1. **Fork** the Project
2. **Create** your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your Changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the Branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

<br>

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

<br>

## 💬 Contact

**Orkhan Gojayev** — [@BlessedDayss](https://github.com/BlessedDayss)

Project Link: [https://github.com/BlessedDayss/OGFinance](https://github.com/BlessedDayss/OGFinance)

<br>

---

<div align="center">

**Built with 💜 using SwiftUI**

<br>

⭐ **Star this repo if you find it useful!** ⭐

<br>

</div>
