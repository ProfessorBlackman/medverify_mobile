# MedVerify Mobile - Drug Verification App

## Overview

MedVerify Mobile is a Flutter-based mobile application designed to verify the authenticity of pharmaceutical drugs through multiple verification methods. The app helps users identify genuine, expired, recalled, or counterfeit medications by scanning barcodes, FDA numbers, or performing text-based searches.

## Key Features

### 🔍 Multi-Modal Drug Verification
- **Barcode Scanning**: Real-time barcode scanning using device camera
- **FDA Number Recognition**: OCR-based FDA number extraction from drug packaging
- **Manual Search**: Text-based fuzzy search for drug verification
- **Image Upload**: Photo capture and upload for verification assistance

### 📱 Core Functionality
- **Real-time Scanning**: Live camera feed with barcode detection
- **Offline History**: Local storage of scan history using Hive database
- **Cross-platform**: Supports both Android and iOS platforms
- **Dark/Light Theme**: Automatic theme switching based on system preferences

### 📊 Analytics & Monitoring
- **Firebase Analytics**: User behavior tracking and app performance monitoring
- **Location Services**: Geographic data collection for verification analytics
- **Error Tracking**: Sentry integration for crash reporting and error monitoring
- **User Identification**: Anonymous user tracking for analytics

### 🔔 Notifications & Engagement
- **Push Notifications**: Firebase Cloud Messaging integration
- **Local Notifications**: In-app notification system
- **Feedback System**: User feedback collection and submission

## Architecture

### 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point and routing
├── theme.dart               # App theming and color schemes
├── firebase_options.dart    # Firebase configuration
├── models/                  # Data models
│   └── verification_result.dart
├── providers/               # State management
│   └── app_provider.dart
├── screens/                 # UI screens
│   ├── dashboard_screen.dart
│   ├── scanner_screen.dart
│   ├── results_screen.dart
│   ├── history_screen.dart
│   ├── manual_entry_screen.dart
│   ├── welcome_screen.dart
│   ├── splash_screen.dart
│   ├── info_hub_screen.dart
│   ├── feedback_screen.dart
│   └── how_it_works_screen.dart
├── services/                # Business logic and external integrations
│   ├── verification_service.dart
│   ├── local_database.dart
│   ├── ocr_service.dart
│   ├── analytics_service.dart
│   ├── notifications_service.dart
│   ├── feedback_service.dart
│   └── file_upload_service.dart
├── widgets/                 # Reusable UI components
│   ├── dashboard_widgets.dart
│   ├── scanner_overlay.dart
│   ├── barcode_scanner_modal.dart
│   └── location_input_dialog.dart
└── utils/                   # Utilities and helpers
    ├── globals.dart
    ├── variables.dart
    └── user_identification.dart
```

### 🎯 Design Patterns

#### State Management
- **Provider Pattern**: Uses the Provider package for state management
- **ChangeNotifier**: AppProvider manages app-wide state including scan history
- **Dependency Injection**: Services are injected through Provider

#### Data Layer
- **Repository Pattern**: LocalDatabase service handles data persistence
- **Model Classes**: Structured data models with serialization support
- **Local Storage**: Hive database for offline data storage

#### Service Layer
- **Service Classes**: Separated business logic into dedicated service classes
- **HTTP Client**: RESTful API communication using http package
- **Error Handling**: Comprehensive error handling with Sentry integration

## Technical Stack

### 🛠️ Core Technologies
- **Framework**: Flutter 3.10.4+
- **Language**: Dart
- **State Management**: Provider 6.1.5+
- **Local Database**: Hive 2.2.3+ with Flutter integration

### 📦 Key Dependencies

#### Camera & Scanning
- `mobile_scanner: ^7.1.4` - Barcode scanning functionality
- `camera: ^0.11.3` - Camera access and control
- `google_mlkit_text_recognition: ^0.15.0` - OCR for FDA number extraction
- `image_picker: ^1.2.1` - Image selection from gallery/camera
- `image_cropper: ^11.0.0` - Image editing capabilities

#### Firebase Integration
- `firebase_core: ^4.3.0` - Firebase core functionality
- `firebase_messaging: ^16.1.0` - Push notifications
- `firebase_analytics: ^12.1.0` - Analytics and user tracking

#### UI & UX
- `google_fonts: ^6.3.3` - Custom font integration
- `material_symbols_icons: ^4.2892.0` - Material Design icons
- `flutter_local_notifications: ^19.5.0` - Local notification system

#### Networking & Data
- `http: ^1.6.0` - HTTP client for API communication
- `shared_preferences: ^2.5.4` - Simple key-value storage
- `intl: ^0.20.2` - Internationalization support

#### Location & Utilities
- `geolocator: ^14.0.2` - GPS location services
- `geocoding: ^4.0.0` - Address geocoding
- `url_launcher: ^6.3.2` - External URL handling
- `uuid: ^4.5.2` - UUID generation

#### Development & Monitoring
- `sentry_flutter: ^9.9.1` - Error tracking and performance monitoring
- `hive_generator: ^2.0.1` - Code generation for Hive
- `build_runner: ^2.4.13` - Build system for code generation

## Data Models

### VerificationResult
The core data model representing drug verification information:

```dart
enum VerificationStatus {
  verified,      // Authentic drug
  valid,         // Valid registration
  invalid,       // Invalid/fake drug
  unregistered,  // Not registered with FDA
  expired,       // Past expiry date
  recalled,      // Recalled by manufacturer
  near_expiry,   // Approaching expiry
  pending,       // Verification in progress
}

class VerificationResult {
  final VerificationStatus? status;
  final String? productName;
  final String? manufacturer;
  final String? countryOrigin;
  final String? region;
  final String? regNumber;
  final DateTime? expiryDate;
  final String? activeIngredient;
  final String? email;
  final DateTime? approvalDate;
  final String? postalAddress;
  final String? registrationType;
  final String? imageUrl;
  final String? barcode;
  final String? category;
  final String? message;
  final DateTime? scannedAt;
}
```

## Services Architecture

### VerificationService
Handles drug verification through multiple channels:
- **Barcode Verification**: API endpoint `/barcode?bc={barcode}`
- **Fuzzy Search**: API endpoint `/search?search_term={query}`
- **FDA Number Verification**: Placeholder for FDA-specific verification

### LocalDatabase (Hive)
Manages local data persistence:
- **Scan History**: Stores verification results locally
- **Offline Access**: Enables app functionality without internet
- **Data Serialization**: Automatic conversion between objects and storage

### OCR Service (ML Kit)
Extracts FDA numbers from images:
- **Text Recognition**: Google ML Kit integration
- **Pattern Matching**: Regex-based FDA number extraction
- **Camera Integration**: Real-time text recognition from camera feed

### Analytics Service
Comprehensive user analytics:
- **Firebase Analytics**: User behavior tracking
- **Location Analytics**: Geographic usage patterns
- **Custom Events**: Drug scan tracking with metadata
- **User Properties**: Anonymous user identification

## User Interface

### Theme System
- **Material Design 3**: Modern Material Design implementation
- **Custom Color Palette**: Green-focused healthcare theme
- **Dark/Light Mode**: Automatic theme switching
- **Typography**: Google Fonts (Public Sans, Noto Sans)

### Screen Flow
1. **Welcome/Splash** → First-time user onboarding
2. **Dashboard** → Main hub with quick actions and recent scans
3. **Scanner** → Camera-based barcode scanning
4. **Manual Entry** → Text-based drug search
5. **Results** → Verification results display
6. **History** → Past scan history
7. **Info Hub** → Educational content
8. **Feedback** → User feedback collection

## Backend Integration

### API Endpoints
- **Base URL**: `https://medverify-api.methuselah.site`
- **Barcode Verification**: `GET /barcode?bc={barcode}`
- **Search**: `GET /search?search_term={query}`

### Data Flow
1. User initiates scan/search
2. App processes input (barcode/text/image)
3. API request sent to backend
4. Results processed and displayed
5. Data stored locally for offline access
6. Analytics events logged

## Security & Privacy

### Data Protection
- **Local Storage**: Sensitive data stored locally using Hive encryption
- **Anonymous Analytics**: No personally identifiable information collected
- **Error Reporting**: Sentry integration with privacy controls

### Permissions
- **Camera**: Required for barcode scanning and image capture
- **Location**: Optional for analytics and regional data
- **Storage**: Required for local database and image caching
- **Internet**: Required for API communication and updates

## Development Setup

### Prerequisites
- Flutter SDK 3.10.4+
- Dart SDK
- Android Studio / Xcode for platform-specific development
- Firebase project setup

### Installation
```bash
# Clone repository
git clone <repository-url>

# Install dependencies
flutter pub get

# Generate code (for Hive)
flutter packages pub run build_runner build

# Run the app
flutter run
```

### Configuration
1. **Firebase Setup**: Configure `firebase_options.dart`
2. **API Configuration**: Update backend URL in `lib/utils/variables.dart`
3. **Sentry Setup**: Configure DSN in `main.dart`

## Testing & Quality Assurance

### Code Quality
- **Flutter Lints**: Enforced coding standards
- **Analysis Options**: Configured in `analysis_options.yaml`
- **Error Handling**: Comprehensive try-catch blocks with Sentry reporting

### Performance Monitoring
- **Sentry Integration**: Real-time error tracking and performance monitoring
- **Firebase Analytics**: User engagement and app performance metrics
- **Local Caching**: Optimized data access with Hive database

## Deployment

### Platform Support
- **Android**: Minimum SDK version support
- **iOS**: iOS deployment configuration
- **Cross-platform**: Shared codebase with platform-specific optimizations

### Build Configuration
- **Release Builds**: Optimized for production deployment
- **Debug Builds**: Development and testing configuration
- **Firebase Integration**: Production and staging environment support

## Future Enhancements

### Planned Features
- **Offline OCR**: Local text recognition without internet
- **Multi-language Support**: Internationalization for global markets
- **Advanced Analytics**: Enhanced user behavior insights
- **Social Features**: Community-driven drug verification
- **AI Integration**: Machine learning for improved verification accuracy

### Technical Improvements
- **Performance Optimization**: Enhanced scanning speed and accuracy
- **UI/UX Enhancements**: Improved user experience and accessibility
- **Security Hardening**: Enhanced data protection and privacy controls
- **API Optimization**: Improved backend communication and caching

---

*This documentation provides a comprehensive overview of the MedVerify Mobile application architecture, features, and technical implementation. For specific implementation details, refer to the individual source files in the project repository.*