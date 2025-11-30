# Crypto Assistant 🚀💰

A sophisticated Flutter application that provides AI-driven cryptocurrency investment recommendations with comprehensive market analysis, whale activity tracking, and multi-period performance insights.

## ✨ Features

### 📈 Real-time Market Data
- View top cryptocurrencies with live prices and 24-hour changes
- Interactive price charts with multiple timeframes (24H, 7D, 1M, 1Y)
- Detailed coin information with market cap and trading volume

### 🧠 Advanced AI Analysis
- **Smart Money Recommendations**: Daily AI-powered investment insights
- **Whale Activity Tracking**: Monitor large wallet movements and their impact
- **Multi-Period Performance**: Analyze 1-week, 1-month, and 1-year trends
- **Trading Volume Analysis**: Evaluate market liquidity and momentum
- **Confidence Scoring**: AI-calculated confidence levels for each recommendation
- **Detailed Predictions**: In-depth analysis with actionable insights

### 🔔 Smart Notifications
- Daily alerts at 12:00 PM with investment recommendations
- Tap notifications to view detailed analysis
- Persistent notifications until reviewed

### 🌍 Localization
- **English** and **Russian** language support
- Automatic locale detection
- In-app language switching

### 🎨 Modern UI/UX
- Material 3 design system
- Light and dark theme support
- Smooth animations and transitions
- Responsive layouts for all screen sizes
- Clean, intuitive navigation

## 🏗️ Architecture

This project implements **Clean Architecture** principles with clear separation of concerns:

### Domain Layer (`lib/features/crypto/domain/`)
- **Entities**: Pure Dart business objects
  - `CryptoCoinEntity`: Cryptocurrency data model
  - `RecommendationEntity`: AI recommendation with analysis details
- **Repository Interfaces**: Abstract contracts for data operations
  - `ICryptoRepository`: Defines data access methods

### Data Layer (`lib/features/crypto/data/`)
- **Data Sources**: External data providers
  - `CryptoRemoteDataSource`: API integration and mock data generation
- **Models**: Data transfer objects
  - `CryptoCoinModel`: JSON serialization/deserialization
- **Repository Implementation**: Concrete data access logic
  - `CryptoRepositoryImpl`: Implements `ICryptoRepository`

### Presentation Layer (`lib/features/crypto/presentation/`)
- **ViewModels**: State management with Provider
  - `HomeViewModel`: Manages coin list and recommendations
  - `SettingsViewModel`: Handles app preferences
- **Pages**: Screen components
  - `HomeScreen`: Main dashboard with coin list
  - `CoinDetailScreen`: Detailed coin analysis
  - `SettingsScreen`: App configuration
- **Widgets**: Reusable UI components

### Core Services (`lib/core/services/`)
- `NotificationService`: Local notifications with timezone support

## 🛠️ Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **HTTP Client**: http package
- **Charts**: fl_chart
- **Notifications**: flutter_local_notifications
- **Localization**: flutter_localizations with ARB files
- **Storage**: shared_preferences
- **Architecture**: Clean Architecture with dependency injection

## 📋 Prerequisites

Before you begin, ensure you have:
- **Flutter SDK** (3.0.0 or higher): [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: Included with Flutter
- **IDE**: VS Code (recommended) or Android Studio
- **Xcode** (for iOS/macOS development)
- **Android Studio** (for Android development)

## 🚀 Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd crypto-assistant
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify installation**:
   ```bash
   flutter doctor
   ```

## 📱 Running the App

### Android

1. **Start Android Emulator** or connect a physical device (with USB Debugging enabled)
2. **Run the app**:
   ```bash
   flutter run
   ```
   
   *For multiple devices, use:*
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

### iOS (macOS only)

1. **Open iOS Simulator**:
   ```bash
   open -a Simulator
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

#### Physical iOS Device

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your development team in **Runner > Signing & Capabilities**
3. Connect your iPhone/iPad
4. Run:
   ```bash
   flutter run -d <device-id>
   ```

### macOS Desktop

1. **Enable macOS support** (one-time):
   ```bash
   flutter config --enable-macos-desktop
   ```

2. **Run the app**:
   ```bash
   flutter run -d macos
   ```

## 🔧 Troubleshooting

### Flutter not found
Ensure Flutter SDK `bin` directory is in your system PATH:
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

### CocoaPods errors (iOS/macOS)
```bash
cd ios  # or cd macos
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### Notification permissions
- **iOS**: Permission requested on first launch
- **Android 13+**: Permission requested automatically
- **Manual**: Check app settings if notifications don't appear

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

## 📁 Project Structure

```
lib/
├── core/
│   └── services/
│       └── notification_service.dart
├── features/
│   ├── crypto/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── viewmodels/
│   │       └── widgets/
│   └── settings/
│       └── presentation/
│           ├── pages/
│           └── viewmodels/
├── l10n/
│   ├── app_en.arb
│   ├── app_ru.arb
│   └── app_localizations.dart
└── main.dart
```

## 🌐 Localization

The app supports multiple languages through ARB (Application Resource Bundle) files:

- **English**: `lib/l10n/app_en.arb`
- **Russian**: `lib/l10n/app_ru.arb`

To add a new language:
1. Create `app_<locale>.arb` in `lib/l10n/`
2. Add locale to `supportedLocales` in `main.dart`
3. Run `flutter gen-l10n`

## 🧪 Testing

Run tests:
```bash
flutter test
```

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### macOS
```bash
flutter build macos --release
```

## 📝 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Contact

For questions or support, please open an issue on GitHub.