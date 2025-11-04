# 🎵 Sonus Music Player

A modern, feature-rich music player application built with Flutter, offering a premium music listening experience with advanced features, beautiful UI, and comprehensive functionality.

![Flutter](https://img.shields.io/badge/Flutter-3.5+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### 🎵 Music Playback
- **Local Music Library**: Scan and play music from device storage
- **Audio Format Support**: MP3, FLAC, AAC, WAV, and other popular formats
- **High-Quality Playback**: Professional audio engine with just_audio
- **Background Playback**: Continue playing when app is minimized
- **Lock Screen Controls**: Full media controls on device lock screen
- **Queue Management**: Dynamic playlist management with queue controls

### 🎛️ Audio Enhancements (Not implemented yet in Audio Engine)
- **10-Band Equalizer**: Professional-grade equalizer with presets
- **Custom EQ Presets**: Rock, Pop, Jazz, Classical, Electronic, Custom
- **Audio Effects**: Bass boost, treble enhancement, spatial audio
- **Waveform Visualization**: Visual representation of audio waveforms

### 📱 Responsive Design
- **Multi-Device Support**: Optimized for phones, tablets, and different screen sizes
- **Orientation Support**: Automatic layout adaptation for portrait and landscape
- **Tablet Layout**: Specialized full-screen player with queue management for tablets
- **Adaptive UI**: Dynamic sizing and spacing based on screen dimensions
- **Modern Material Design**: Clean, intuitive interface following Material Design principles

### 🎨 Theme System
- **Dark/Light Themes**: Theme switching on user preferences
- **Custom Color Schemes**: Multiple color palettes and accent colors
- **Glass Morphism Effects**: Modern translucent UI elements
- **Dynamic Theming**: Real-time theme changes without app restart

### 🔔 Notification System
- **Push Notifications**: Firebase Cloud Messaging integration
- **In-App Messages**: Rich media notifications with images and actions
- **Notification Settings**: Granular control over notification types
- **Quiet Hours**: Customizable do-not-disturb periods

### ⏰ Sleep Timer
- **Customizable Duration**: Set timer from 5 minutes to 2 hours
- **Visual Timer Display**: Real-time countdown with modern UI
- **Auto-Stop Music**: Automatically stops playback when timer expires
- **Persistent Notifications**: Shows countdown in notification panel

### 📚 Music Library Management
- **Smart Organization**: Automatic sorting by artist, album, genre, year
- **Playlist Creation**: Create, edit, and manage custom playlists
- **Recently Played**: Track and access recently played songs
- **Favorites System**: Mark and manage favorite songs
- **Search Functionality**: Powerful search across all music metadata
- **Album Artwork**: Automatic and manual album art management

### 🏆 Achievements & Statistics
- **Achievement System**: Unlock achievements based on listening habits
- **Listening Statistics**: Track play time, play count, and listening patterns
- **Visual Progress**: Beautiful achievement badges and progress indicators
- **Personal Insights**: Detailed analytics about your music preferences

### 🔐 User Authentication
- **Firebase Authentication**: Secure user authentication with Firebase
- **Google Sign-In**: Quick login with Google account
- **Cloud Sync**: Sync playlists and preferences across devices

### 👨‍💼 Admin Dashboard
- **User Management**: Admin panel for user management
- **FCM Management**: Manage Firebase Cloud Messaging tokens
- **Enhanced Notifications**: Send custom notifications to users
- **Analytics**: View app usage statistics

### 🌍 Localization
- **Multi-Language Support**: English and Myanmar language support
- **Easy Extension**: Simple structure for adding more languages

## 📸 Screenshots

> _Screenshots coming soon_

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.5.4)
- Dart SDK (>=3.5.4)
- Android Studio / Xcode (for mobile development)
- Firebase project setup (for authentication and notifications)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kooo12/sonus_music.git
   cd sonus_music
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add your Android/iOS app to the Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in `android/app/` and `ios/Runner/` respectively
   - Add Firebase configuration in `lib/main.dart`

4. **Configure API Keys**
   - Add your Firebase API keys to `lib/main.dart`
   - Add Google Cloud Service Account credentials if needed

5. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── app/
│   ├── bindings/          # GetX bindings
│   ├── controllers/       # App controllers
│   ├── data/
│   │   ├── database/      # Local database (SQLite)
│   │   ├── models/        # Data models
│   │   ├── repository/    # Data repositories
│   │   └── services/      # Business logic services
│   ├── helper_widgets/    # Reusable widgets
│   ├── pages/             # App screens/pages
│   ├── routes/            # App routing
│   ├── translations/      # Localization files
│   └── ui/                # UI themes and styles
├── constants.dart         # App constants
└── main.dart              # App entry point
```

## 🛠️ Tech Stack

### Core
- **Flutter** - UI framework
- **Dart** - Programming language
- **GetX** - State management and dependency injection

### Audio & Media
- **just_audio** - Audio playback
- **audio_service** - Background audio service
- **audio_session** - Audio session management
- **audio_waveforms** - Waveform visualization
- **on_audio_query** - Local audio file querying

### Backend & Authentication
- **Firebase Core** - Firebase initialization
- **Firebase Auth** - User authentication
- **Firebase Messaging** - Push notifications
- **Firebase Analytics** - App analytics
- **Cloud Firestore** - Cloud database
- **Google Sign-In** - Google authentication

### Storage & Database
- **sqflite** - Local SQLite database
- **shared_preferences** - Local key-value storage
- **flutter_secure_storage** - Secure storage for sensitive data

### UI & Design
- **iconsax_flutter** - Icon pack
- **cached_network_image** - Image caching
- **confetti** - Achievement animations

### Utilities
- **http** - HTTP requests
- **file_picker** - File selection
- **url_launcher** - Launch external URLs
- **device_info_plus** - Device information

## 🔒 Security

- **Secrets Management**: API keys and credentials are excluded from version control
- **Secure Storage**: Sensitive data stored using `flutter_secure_storage`
- **Firebase Security Rules**: Properly configured Firestore security rules
- **User Privacy**: Data encryption and secure authentication

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**KoOo**

- GitHub: [@kooo12](https://github.com/kooo12)
- Project Repository: [sonus_music](https://github.com/kooo12/sonus_music)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All package maintainers for their excellent work
- Firebase team for robust backend services

## 📄 License

Copyright (c) 2025 Kooo. All rights reserved.

---

⭐ If you find this project interesting, please give it a star!

