@echo off
REM 🔧 MIZZ MUSIC PLAYER - PACKAGE MIGRATION SCRIPT (Windows)
REM Migrates from old packages to latest stable versions

echo ================================================
echo 🚀 Mizz Music Player Package Migration
echo ================================================
echo.

REM Step 1: Backup
echo 📦 Step 1: Creating backup...
git add .
git commit -m "Backup before package migration - %date% %time%"
if errorlevel 1 echo No changes to commit
echo.

REM Step 2: Clean
echo 🧹 Step 2: Cleaning build artifacts...
flutter clean
if exist pubspec.lock del /f pubspec.lock
if exist .dart_tool rmdir /s /q .dart_tool
if exist build rmdir /s /q build
echo ✅ Clean complete
echo.

REM Step 3: Backup pubspec
echo 💾 Step 3: Backing up pubspec.yaml...
copy /y pubspec.yaml pubspec.yaml.backup
echo ✅ Backup saved as pubspec.yaml.backup
echo.

REM Step 4: Update pubspec
echo 📝 Step 4: Updating pubspec.yaml...
echo ⚠️  MANUAL ACTION REQUIRED:
echo    1. Open pubspec_UPDATED.yaml
echo    2. Copy all contents
echo    3. Paste into pubspec.yaml
echo    4. Save the file
echo.
pause

REM Step 5: Get packages
echo.
echo 📥 Step 5: Downloading new packages...
flutter pub get
if errorlevel 1 (
    echo ❌ flutter pub get failed!
    echo Restoring backup...
    copy /y pubspec.yaml.backup pubspec.yaml
    flutter pub get
    exit /b 1
)
echo ✅ Packages downloaded
echo.

REM Step 6: Upgrade
echo ⬆️ Step 6: Upgrading to latest versions...
flutter pub upgrade --major-versions
if errorlevel 1 (
    echo ❌ flutter pub upgrade failed!
    exit /b 1
)
echo ✅ Packages upgraded
echo.

REM Step 7: Update code
echo 📝 Step 7: Updating code files...
echo ⚠️  MANUAL ACTION REQUIRED:
echo    1. Copy lib\core\download_manager_UPDATED.dart
echo    2. Rename to lib\core\download_manager.dart (replace existing)
echo    3. Update any palette_generator usage (see MIGRATION_GUIDE.md)
echo.
pause

REM Step 8: Analyze
echo.
echo 🔍 Step 8: Analyzing code...
flutter analyze
echo.

REM Step 9: Check outdated
echo 📊 Step 9: Checking package versions...
flutter pub outdated
echo.

REM Step 10: Test build
echo 🏗️ Step 10: Testing debug build...
flutter build apk --debug
if errorlevel 1 (
    echo ❌ Build failed! Check errors above.
    exit /b 1
)
echo ✅ Debug build successful
echo.

REM Final message
echo ================================================
echo ✅ Migration Complete!
echo ================================================
echo.
echo 📋 Next Steps:
echo    1. Review MIGRATION_GUIDE.md
echo    2. Test all features:
echo       - YouTube downloads
echo       - Offline playback
echo       - Background audio
echo       - Permissions
echo    3. Run: flutter run
echo.
echo 🎯 Updated Packages:
echo    • youtube_explode_dart: 2.5.3 → 3.0.5
echo    • just_audio: 0.9.36 → 0.10.5
echo    • audio_session: 0.1.21 → 0.2.2
echo    • permission_handler: 11.3.0 → 12.0.1
echo    • palette_generator → image: 4.2.0
echo.
echo 🔗 Documentation:
echo    - MIGRATION_GUIDE.md
echo    - pubspec_UPDATED.yaml
echo    - download_manager_UPDATED.dart
echo.
pause
