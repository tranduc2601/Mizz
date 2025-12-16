import 'package:flutter/material.dart';

/// Supported locales for the app
enum AppLocale {
  vietnamese('vi', 'Tiếng Việt'),
  english('en', 'English');

  final String code;
  final String displayName;
  const AppLocale(this.code, this.displayName);

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.english,
    );
  }
}

/// App Localization - Contains all translated strings
class AppLocalizations {
  final AppLocale locale;

  AppLocalizations(this.locale);

  // Static accessor for easy use throughout the app
  static AppLocalizations of(BuildContext context) {
    return LocalizationProvider.of(context).localizations;
  }

  // ========== Common ==========
  String get appName => _get('appName');
  String get ok => _get('ok');
  String get cancel => _get('cancel');
  String get save => _get('save');
  String get delete => _get('delete');
  String get edit => _get('edit');
  String get close => _get('close');
  String get loading => _get('loading');
  String get error => _get('error');
  String get success => _get('success');
  String get confirm => _get('confirm');
  String get yes => _get('yes');
  String get no => _get('no');

  // ========== Navigation ==========
  String get home => _get('home');
  String get settings => _get('settings');
  String get about => _get('about');
  String get myLibrary => _get('myLibrary');
  String get playlists => _get('playlists');
  String get favorites => _get('favorites');
  String get recentlyPlayed => _get('recentlyPlayed');

  // ========== Music ==========
  String get addNewSong => _get('addNewSong');
  String get songName => _get('songName');
  String get artist => _get('artist');
  String get enterSongName => _get('enterSongName');
  String get enterArtist => _get('enterArtist');
  String get musicSource => _get('musicSource');
  String get linkUrl => _get('linkUrl');
  String get localFile => _get('localFile');
  String get selectMusicFile => _get('selectMusicFile');
  String get coverImage => _get('coverImage');
  String get addFromCamera => _get('addFromCamera');
  String get addFromGallery => _get('addFromGallery');
  String get enterMusicUrl => _get('enterMusicUrl');
  String get play => _get('play');
  String get pause => _get('pause');
  String get stop => _get('stop');
  String get nowPlaying => _get('nowPlaying');
  String get yourMusicYourWay => _get('yourMusicYourWay');

  // ========== User Profile ==========
  String get profile => _get('profile');
  String get editProfile => _get('editProfile');
  String get name => _get('name');
  String get email => _get('email');
  String get enterName => _get('enterName');
  String get enterEmail => _get('enterEmail');
  String get logout => _get('logout');
  String get logoutConfirm => _get('logoutConfirm');
  String get changeAvatar => _get('changeAvatar');
  String get takePhoto => _get('takePhoto');
  String get chooseFromGallery => _get('chooseFromGallery');
  String get removeAvatar => _get('removeAvatar');

  // ========== Settings ==========
  String get language => _get('language');
  String get selectLanguage => _get('selectLanguage');
  String get theme => _get('theme');
  String get notifications => _get('notifications');
  String get privacy => _get('privacy');
  String get helpAndSupport => _get('helpAndSupport');

  // ========== Auth ==========
  String get login => _get('login');
  String get register => _get('register');
  String get password => _get('password');
  String get confirmPassword => _get('confirmPassword');
  String get forgotPassword => _get('forgotPassword');
  String get createAccount => _get('createAccount');
  String get alreadyHaveAccount => _get('alreadyHaveAccount');
  String get dontHaveAccount => _get('dontHaveAccount');

  // ========== Errors ==========
  String get errorOccurred => _get('errorOccurred');
  String get networkError => _get('networkError');
  String get invalidEmail => _get('invalidEmail');
  String get invalidPassword => _get('invalidPassword');
  String get fieldRequired => _get('fieldRequired');
  String get songAddedSuccess => _get('songAddedSuccess');
  String get profileUpdatedSuccess => _get('profileUpdatedSuccess');

  // Private method to get localized string
  String _get(String key) {
    return _localizedStrings[locale.code]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }

  // All translations
  static final Map<String, Map<String, String>> _localizedStrings = {
    'vi': {
      // Common
      'appName': 'Mizz',
      'ok': 'OK',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'delete': 'Xóa',
      'edit': 'Chỉnh sửa',
      'close': 'Đóng',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'confirm': 'Xác nhận',
      'yes': 'Có',
      'no': 'Không',

      // Navigation
      'home': 'Trang chủ',
      'settings': 'Cài đặt',
      'about': 'Giới thiệu',
      'myLibrary': 'Thư viện của tôi',
      'playlists': 'Danh sách phát',
      'favorites': 'Yêu thích',
      'recentlyPlayed': 'Đã phát gần đây',

      // Music
      'addNewSong': 'Thêm bài hát mới',
      'songName': 'Tên bài hát',
      'artist': 'Nghệ sĩ',
      'enterSongName': 'Nhập tên bài hát',
      'enterArtist': 'Nhập tên nghệ sĩ',
      'musicSource': 'Nguồn nhạc',
      'linkUrl': 'Đường dẫn URL',
      'localFile': 'Tệp cục bộ',
      'selectMusicFile': 'Chọn tệp nhạc',
      'coverImage': 'Ảnh bìa',
      'addFromCamera': 'Chụp ảnh',
      'addFromGallery': 'Chọn từ thư viện',
      'enterMusicUrl': 'Nhập URL nhạc (YouTube, TikTok...)',
      'play': 'Phát',
      'pause': 'Tạm dừng',
      'stop': 'Dừng',
      'nowPlaying': 'Đang phát',
      'yourMusicYourWay': 'Âm nhạc của bạn, theo cách của bạn',

      // User Profile
      'profile': 'Hồ sơ',
      'editProfile': 'Chỉnh sửa hồ sơ',
      'name': 'Tên',
      'email': 'Email',
      'enterName': 'Nhập tên của bạn',
      'enterEmail': 'Nhập email của bạn',
      'logout': 'Đăng xuất',
      'logoutConfirm': 'Bạn có chắc muốn đăng xuất?',
      'changeAvatar': 'Đổi ảnh đại diện',
      'takePhoto': 'Chụp ảnh',
      'chooseFromGallery': 'Chọn từ thư viện',
      'removeAvatar': 'Xóa ảnh đại diện',

      // Settings
      'language': 'Ngôn ngữ',
      'selectLanguage': 'Chọn ngôn ngữ',
      'theme': 'Giao diện',
      'notifications': 'Thông báo',
      'privacy': 'Quyền riêng tư',
      'helpAndSupport': 'Trợ giúp & Hỗ trợ',

      // Auth
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'password': 'Mật khẩu',
      'confirmPassword': 'Xác nhận mật khẩu',
      'forgotPassword': 'Quên mật khẩu?',
      'createAccount': 'Tạo tài khoản',
      'alreadyHaveAccount': 'Đã có tài khoản?',
      'dontHaveAccount': 'Chưa có tài khoản?',

      // Errors
      'errorOccurred': 'Đã xảy ra lỗi',
      'networkError': 'Lỗi kết nối mạng',
      'invalidEmail': 'Email không hợp lệ',
      'invalidPassword': 'Mật khẩu không hợp lệ',
      'fieldRequired': 'Trường này là bắt buộc',
      'songAddedSuccess': 'Đã thêm bài hát thành công!',
      'profileUpdatedSuccess': 'Đã cập nhật hồ sơ thành công!',
    },
    'en': {
      // Common
      'appName': 'Mizz',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',

      // Navigation
      'home': 'Home',
      'settings': 'Settings',
      'about': 'About',
      'myLibrary': 'My Library',
      'playlists': 'Playlists',
      'favorites': 'Favorites',
      'recentlyPlayed': 'Recently Played',

      // Music
      'addNewSong': 'Add New Song',
      'songName': 'Song Name',
      'artist': 'Artist',
      'enterSongName': 'Enter song name',
      'enterArtist': 'Enter artist name',
      'musicSource': 'Music Source',
      'linkUrl': 'URL Link',
      'localFile': 'Local File',
      'selectMusicFile': 'Select Music File',
      'coverImage': 'Cover Image',
      'addFromCamera': 'Take Photo',
      'addFromGallery': 'Choose from Gallery',
      'enterMusicUrl': 'Enter music URL (YouTube, TikTok...)',
      'play': 'Play',
      'pause': 'Pause',
      'stop': 'Stop',
      'nowPlaying': 'Now Playing',
      'yourMusicYourWay': 'Your Music, Your Way',

      // User Profile
      'profile': 'Profile',
      'editProfile': 'Edit Profile',
      'name': 'Name',
      'email': 'Email',
      'enterName': 'Enter your name',
      'enterEmail': 'Enter your email',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to logout?',
      'changeAvatar': 'Change Avatar',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'removeAvatar': 'Remove Avatar',

      // Settings
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'theme': 'Theme',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'helpAndSupport': 'Help & Support',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'forgotPassword': 'Forgot Password?',
      'createAccount': 'Create Account',
      'alreadyHaveAccount': 'Already have an account?',
      'dontHaveAccount': "Don't have an account?",

      // Errors
      'errorOccurred': 'An error occurred',
      'networkError': 'Network connection error',
      'invalidEmail': 'Invalid email address',
      'invalidPassword': 'Invalid password',
      'fieldRequired': 'This field is required',
      'songAddedSuccess': 'Song added successfully!',
      'profileUpdatedSuccess': 'Profile updated successfully!',
    },
  };
}

/// Localization Provider - Provides localization state across the app
class LocalizationProvider extends InheritedNotifier<LocalizationController> {
  const LocalizationProvider({
    super.key,
    required LocalizationController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocalizationController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<LocalizationProvider>();
    return provider!.notifier!;
  }

  AppLocalizations get localizations => notifier!.localizations;
}

/// Localization Controller - Manages language state
class LocalizationController extends ChangeNotifier {
  AppLocale _locale;
  late AppLocalizations _localizations;

  LocalizationController({AppLocale locale = AppLocale.english})
    : _locale = locale {
    _localizations = AppLocalizations(_locale);
  }

  AppLocale get locale => _locale;
  AppLocalizations get localizations => _localizations;

  void setLocale(AppLocale locale) {
    if (_locale != locale) {
      _locale = locale;
      _localizations = AppLocalizations(_locale);
      notifyListeners();
    }
  }

  void setLocaleFromCode(String code) {
    setLocale(AppLocale.fromCode(code));
  }
}
