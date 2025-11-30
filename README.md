# Crypto Assistant 🚀

A Flutter application that provides daily AI-driven cryptocurrency investment recommendations.

## Features
- 📈 **Real-time Crypto Quotes**: View top cryptocurrencies with current prices and 24h changes.
- 🧠 **AI Recommendations**: Daily "Smart Money" insights based on simulated market analysis and whale activity.
- 🔔 **Daily Alerts**: Local notifications at 12:00 PM to check your daily tip.
- 🎨 **Modern UI**: Clean, Material 3 design.

## Prerequisites

Before you begin, ensure you have the following installed:
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: Included with Flutter.
- **IDE**: VS Code (recommended) or Android Studio.
- **Xcode** (for iOS/macOS) and **Android Studio** (for Android).

## Installation

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd crypto-assistant
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

## How to Run

### 📱 Android

1.  **Open Android Emulator** or connect a physical Android device (ensure USB Debugging is on).
2.  Run the app:
    ```bash
    flutter run
    ```
    *Note: If you have multiple devices connected, use `flutter devices` to list them and `flutter run -d <device-id>` to specify one.*

### 🍎 iOS (macOS only)

1.  **Open iOS Simulator**:
    ```bash
    open -a Simulator
    ```
2.  **Run the app**:
    ```bash
    flutter run
    ```

#### Running on Physical iOS Device
1.  Open `ios/Runner.xcworkspace` in Xcode.
2.  Select your development team in **Runner > Signing & Capabilities**.
3.  Connect your iPhone/iPad.
4.  Run from Xcode or terminal:
    ```bash
    flutter run -d <device-id>
    ```

### 💻 macOS Desktop

1.  Enable macOS desktop support (if not already enabled):
    ```bash
    flutter config --enable-macos-desktop
    ```
2.  Run the app:
    ```bash
    flutter run -d macos
    ```

## Troubleshooting

-   **"Command not found: flutter"**: Ensure the Flutter SDK `bin` directory is added to your system PATH.
-   **CocoaPods errors (iOS)**:
    ```bash
    cd ios
    rm -rf Pods
    rm Podfile.lock
    pod install
    cd ..
    ```
-   **Notification Permissions**:
    -   **iOS**: The app will request permission on first launch.
    -   **Android 13+**: The app should request permission automatically. If not, check App Settings.

## Architecture

This project follows **Clean Architecture** principles:
-   **Domain Layer**: Entities and Repository Interfaces (Pure Dart).
-   **Data Layer**: API implementation, Models, and Repository logic.
-   **Presentation Layer**: ViewModels (Provider) and UI Widgets.