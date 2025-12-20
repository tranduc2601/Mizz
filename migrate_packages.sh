#!/bin/bash

# 🔧 MIZZ MUSIC PLAYER - PACKAGE MIGRATION SCRIPT
# Migrates from old packages to latest stable versions
# Run this script in your project root directory

echo "🚀 Starting Mizz Music Player Package Migration..."
echo "=================================================="

# Step 1: Backup current state
echo ""
echo "📦 Step 1: Creating backup..."
git add .
git commit -m "Backup before package migration - $(date '+%Y-%m-%d %H:%M:%S')" || echo "No changes to commit"

# Step 2: Clean build artifacts
echo ""
echo "🧹 Step 2: Cleaning build artifacts..."
flutter clean
rm -rf pubspec.lock
rm -rf .dart_tool
rm -rf build/
echo "✅ Clean complete"

# Step 3: Backup current pubspec.yaml
echo ""
echo "💾 Step 3: Backing up pubspec.yaml..."
cp pubspec.yaml pubspec.yaml.backup
echo "✅ Backup saved as pubspec.yaml.backup"

# Step 4: Update pubspec.yaml
echo ""
echo "📝 Step 4: Updating pubspec.yaml..."
echo "⚠️  MANUAL ACTION REQUIRED:"
echo "   1. Copy contents from pubspec_UPDATED.yaml"
echo "   2. Paste into pubspec.yaml"
echo "   3. Save the file"
echo ""
read -p "Press Enter when ready to continue..."

# Step 5: Get new packages
echo ""
echo "📥 Step 5: Downloading new packages..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ flutter pub get failed!"
    echo "Restoring backup..."
    cp pubspec.yaml.backup pubspec.yaml
    flutter pub get
    exit 1
fi

echo "✅ Packages downloaded"

# Step 6: Upgrade packages
echo ""
echo "⬆️ Step 6: Upgrading to latest versions..."
flutter pub upgrade --major-versions

if [ $? -ne 0 ]; then
    echo "❌ flutter pub upgrade failed!"
    exit 1
fi

echo "✅ Packages upgraded"

# Step 7: Update code files
echo ""
echo "📝 Step 7: Updating code files..."
echo "⚠️  MANUAL ACTION REQUIRED:"
echo "   1. Replace lib/core/download_manager.dart with download_manager_UPDATED.dart"
echo "   2. Update any files using palette_generator (see MIGRATION_GUIDE.md)"
echo "   3. Update audio player files (see examples in guide)"
echo ""
read -p "Press Enter when code updates are complete..."

# Step 8: Analyze code
echo ""
echo "🔍 Step 8: Analyzing code for issues..."
flutter analyze

# Step 9: Check for outdated packages
echo ""
echo "📊 Step 9: Checking package versions..."
flutter pub outdated

# Step 10: Test build
echo ""
echo "🏗️ Step 10: Testing debug build..."
flutter build apk --debug

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Check errors above."
    exit 1
fi

echo "✅ Debug build successful"

# Step 11: Final verification
echo ""
echo "✅ Migration Complete!"
echo "======================"
echo ""
echo "📋 Next Steps:"
echo "1. Review MIGRATION_GUIDE.md for breaking changes"
echo "2. Test all features thoroughly:"
echo "   - YouTube URL parsing"
echo "   - Download functionality"
echo "   - Offline playback"
echo "   - Background audio"
echo "   - Permissions"
echo "   - File picker"
echo "3. Run app: flutter run"
echo "4. Monitor logs for any warnings"
echo ""
echo "🎯 Package Versions Updated:"
echo "   • youtube_explode_dart: 2.5.3 → 3.0.5"
echo "   • just_audio: 0.9.36 → 0.10.5"
echo "   • audio_session: 0.1.21 → 0.2.2"
echo "   • permission_handler: 11.3.0 → 12.0.1"
echo "   • palette_generator → image: 4.2.0"
echo ""
echo "🔗 Documentation:"
echo "   - MIGRATION_GUIDE.md - Full migration details"
echo "   - pubspec_UPDATED.yaml - New package config"
echo "   - download_manager_UPDATED.dart - Updated download code"
echo ""
