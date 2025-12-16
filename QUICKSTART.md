# 🚀 Quick Start Guide - Galaxy Music Player

## Running the App

```bash
# Get dependencies
flutter pub get

# Run on your device/emulator
flutter run

# Run on a specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

## 🎮 User Interactions

### Navigation
- **Hamburger Menu (Top Left):** Opens left drawer with menu options
- **User Avatar (Top Right):** Opens right drawer with profile and favorites

### 3D Carousel Controls
- **Swipe Left/Right:** Rotate the carousel
- **Tap Side Card:** Brings that card to the center position
- **Tap Center Card:** Toggle play/pause mode
- **Previous/Next Buttons:** Navigate between songs
- **Heart Icon:** Toggle favorite status

## 🔧 Feature Management (Plug-and-Play)

### To Remove the Music Carousel Feature

Open [lib/main.dart](lib/main.dart) and comment out:

```dart
void _registerFeatures() {
  final registry = FeatureRegistry();
  
  // Comment this line to remove the carousel:
  // registry.register(MusicCarouselFeature());
  
  registry.register(UserProfileFeature());
}
```

**Result:** The app will show a "Music Carousel not available" message instead of crashing.

### To Remove the User Profile Feature

```dart
void _registerFeatures() {
  final registry = FeatureRegistry();
  
  registry.register(MusicCarouselFeature());
  
  // Comment this line to remove user profile:
  // registry.register(UserProfileFeature());
}
```

**Result:** The avatar will still appear, but clicking it shows a fallback drawer.

## 📦 Adding Custom Features

### Step 1: Create Feature Files

Create a new folder: `lib/features/my_feature/`

Add these files:
- `my_feature_view.dart` - Your widget
- `my_feature_feature.dart` - Feature module class

### Step 2: Implement FeatureModule

```dart
// lib/features/my_feature/my_feature_feature.dart
import 'package:flutter/material.dart';
import '../../core/feature_registry.dart';
import 'my_feature_view.dart';

class MyFeature extends FeatureModule {
  @override
  String get id => 'my_feature';

  @override
  String get name => 'My Feature';

  @override
  String get description => 'Description of my feature';

  @override
  Widget? buildWidget(BuildContext context) {
    return const MyFeatureView();
  }
}
```

### Step 3: Register Your Feature

In [lib/main.dart](lib/main.dart):

```dart
import 'features/my_feature/my_feature_feature.dart';

void _registerFeatures() {
  final registry = FeatureRegistry();
  
  registry.register(MusicCarouselFeature());
  registry.register(UserProfileFeature());
  registry.register(MyFeature()); // Add your feature
}
```

### Step 4: Use Your Feature

In any widget:

```dart
FeatureWidget(
  featureId: 'my_feature',
  fallback: Text('My Feature not available'),
)
```

## 🎨 Customizing the Theme

Edit [lib/core/theme.dart](lib/core/theme.dart) to change colors:

```dart
class GalaxyTheme {
  // Change these colors to customize the theme
  static const Color deepSpace = Color(0xFF0A0E27);
  static const Color nebulaPurple = Color(0xFF2D1B69);
  static const Color cosmicViolet = Color(0xFF6B2D9E);
  static const Color stardustPink = Color(0xFFB968C7);
  // ...
}
```

## 📝 Project Structure Overview

```
lib/
├── core/                           # Core functionality
│   ├── theme.dart                 # Galaxy theme & colors
│   └── feature_registry.dart      # Plug-and-play system
│
├── features/                       # All features (modular)
│   ├── music_carousel/
│   │   ├── music_model.dart       # Data models
│   │   ├── carousel_view.dart     # 3D carousel widget
│   │   └── music_carousel_feature.dart
│   │
│   └── user_profile/
│       ├── user_profile_view.dart
│       └── user_profile_feature.dart
│
├── main_screen.dart               # Main layout scaffold
└── main.dart                      # App entry point
```

## 🧪 Testing

Run tests:

```bash
flutter test
```

Run specific test:

```bash
flutter test test/widget_test.dart
```

## 📱 Building for Production

```bash
# Android APK
flutter build apk

# Android App Bundle (for Play Store)
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web
```

## 🐛 Common Issues

### Issue: Hot reload not working
**Solution:** Use hot restart instead:
```bash
# Press 'R' in terminal, or
flutter run --hot
```

### Issue: Carousel animation choppy
**Solution:** Run in release mode for better performance:
```bash
flutter run --release
```

### Issue: Import errors
**Solution:** Run:
```bash
flutter clean
flutter pub get
```

## 💡 Tips

1. **Performance:** The 3D transformations work best in release mode
2. **Customization:** Each feature can be styled independently
3. **Scalability:** Add as many features as needed without modifying core code
4. **Testing:** Test removing features to verify true decoupling

## 📚 Key Files to Understand

1. **[lib/main.dart](lib/main.dart)** - Feature registration & app entry
2. **[lib/core/feature_registry.dart](lib/core/feature_registry.dart)** - Plug-and-play system
3. **[lib/features/music_carousel/carousel_view.dart](lib/features/music_carousel/carousel_view.dart)** - 3D carousel logic
4. **[lib/main_screen.dart](lib/main_screen.dart)** - Main layout structure

## 🎯 Next Steps

- Add real music player functionality
- Integrate with music APIs
- Add more features (equalizer, volume control, etc.)
- Persist user favorites
- Add animations and transitions
- Implement actual audio playback

Enjoy building with the Galaxy Music Player! 🎵✨
