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
  String get songs => _get('songs');
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

  // ========== Music Player ==========
  String get noTrackLoaded => _get('noTrackLoaded');
  String get loadingAudio => _get('loadingAudio');
  String get playing => _get('playing');
  String get paused => _get('paused');
  String get stopped => _get('stopped');
  String get unknownArtist => _get('unknownArtist');
  String get unknownTitle => _get('unknownTitle');
  String get pickLocalFile => _get('pickLocalFile');
  String get playYouTubeLink => _get('playYouTubeLink');
  String get pasteYouTubeUrl => _get('pasteYouTubeUrl');
  String get smartAudioDemo => _get('smartAudioDemo');

  // ========== Dialogs & Actions ==========
  String get tapToAddImage => _get('tapToAddImage');
  String get fileSelected => _get('fileSelected');
  String get tapToUploadFile => _get('tapToUploadFile');
  String get uploadFile => _get('uploadFile');
  String get link => _get('link');
  String get addSong => _get('addSong');
  String get pleaseEnterSongName => _get('pleaseEnterSongName');
  String get pleaseEnterMusicLink => _get('pleaseEnterMusicLink');
  String get pleaseSelectMusicFile => _get('pleaseSelectMusicFile');
  String get storagePermissionRequired => _get('storagePermissionRequired');
  String get comingSoon => _get('comingSoon');
  String get version => _get('version');
  String get manageNotifications => _get('manageNotifications');
  String get done => _get('done');

  // ========== YouTube Download ==========
  String get downloadForFasterPlayback => _get('downloadForFasterPlayback');
  String get youtubeDownloadDescription => _get('youtubeDownloadDescription');
  String get downloadingAudio => _get('downloadingAudio');
  String get downloadComplete => _get('downloadComplete');
  String get downloadCompleteDescription => _get('downloadCompleteDescription');
  String get downloadFailed => _get('downloadFailed');
  String get downloadNow => _get('downloadNow');
  String get skipForNow => _get('skipForNow');

  // ========== In-App Updates ==========
  String get updates => _get('updates');
  String get checkForUpdates => _get('checkForUpdates');
  String get checkingForUpdates => _get('checkingForUpdates');
  String get newVersionAvailable => _get('newVersionAvailable');
  String get currentVersion => _get('currentVersion');
  String get youAreUpToDate => _get('youAreUpToDate');
  String get updateAvailable => _get('updateAvailable');
  String get whatsNew => _get('whatsNew');
  String get later => _get('later');
  String get updateNow => _get('updateNow');
  String get downloading => _get('downloading');
  String get openingInstaller => _get('openingInstaller');
  String get retry => _get('retry');
  String get newLabel => _get('newLabel');

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
      'songs': 'Bài hát',
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

      // Music Player
      'noTrackLoaded': 'Chưa có bài hát',
      'loadingAudio': 'Đang tải nhạc...',
      'playing': 'Đang phát',
      'paused': 'Tạm dừng',
      'stopped': 'Đã dừng',
      'unknownArtist': 'Nghệ sĩ không xác định',
      'unknownTitle': 'Không có tiêu đề',
      'pickLocalFile': 'Chọn tệp nhạc',
      'playYouTubeLink': 'Phát link YouTube',
      'pasteYouTubeUrl': 'Dán URL YouTube vào đây',
      'smartAudioDemo': 'Demo Smart Audio',

      // Dialogs & Actions
      'tapToAddImage': 'Nhấn để thêm ảnh',
      'fileSelected': 'Đã chọn tệp',
      'tapToUploadFile': 'Nhấn để tải lên MP3/MP4',
      'uploadFile': 'Tải lên tệp',
      'link': 'Đường dẫn',
      'addSong': 'Thêm bài hát',
      'pleaseEnterSongName': 'Vui lòng nhập tên bài hát',
      'pleaseEnterMusicLink': 'Vui lòng nhập link nhạc',
      'pleaseSelectMusicFile': 'Vui lòng chọn tệp nhạc',
      'storagePermissionRequired': 'Cần quyền truy cập bộ nhớ để tải tệp nhạc',
      'comingSoon': 'Sắp có!',
      'version': 'Phiên bản',
      'manageNotifications': 'Quản lý thông báo',
      'done': 'Xong',

      // YouTube Download
      'downloadForFasterPlayback': 'Tải xuống để phát nhanh hơn?',
      'youtubeDownloadDescription':
          'Bạn có muốn tải bài hát này về máy không? Điều này sẽ giúp phát nhạc nhanh hơn nhiều cho những lần sau.',
      'downloadingAudio': 'Đang tải nhạc...',
      'downloadComplete': 'Tải xuống hoàn tất!',
      'downloadCompleteDescription':
          'Bài hát sẽ được phát ngay lập tức từ bây giờ.',
      'downloadFailed': 'Tải xuống thất bại. Vui lòng thử lại sau.',
      'downloadNow': 'Tải ngay',
      'skipForNow': 'Bỏ qua',

      // In-App Updates
      'updates': 'Cập nhật',
      'checkForUpdates': 'Kiểm tra cập nhật',
      'checkingForUpdates': 'Đang kiểm tra cập nhật...',
      'newVersionAvailable': 'Có phiên bản mới',
      'currentVersion': 'Phiên bản hiện tại',
      'youAreUpToDate': 'Bạn đang sử dụng phiên bản mới nhất',
      'updateAvailable': 'Có bản cập nhật mới',
      'whatsNew': 'Có gì mới',
      'later': 'Để sau',
      'updateNow': 'Cập nhật ngay',
      'downloading': 'Đang tải...',
      'openingInstaller': 'Đang mở trình cài đặt...',
      'retry': 'Thử lại',
      'newLabel': 'MỚI',
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
      'songs': 'Songs',
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

      // Music Player
      'noTrackLoaded': 'No track loaded',
      'loadingAudio': 'Loading audio...',
      'playing': 'Playing',
      'paused': 'Paused',
      'stopped': 'Stopped',
      'unknownArtist': 'Unknown Artist',
      'unknownTitle': 'Unknown Title',
      'pickLocalFile': 'Pick Local Audio File',
      'playYouTubeLink': 'Play YouTube Link',
      'pasteYouTubeUrl': 'Paste YouTube URL here',
      'smartAudioDemo': 'Smart Audio Handler Demo',

      // Dialogs & Actions
      'tapToAddImage': 'Tap to add image',
      'fileSelected': 'File selected',
      'tapToUploadFile': 'Tap to upload MP3/MP4 file',
      'uploadFile': 'Upload File',
      'link': 'Link',
      'addSong': 'Add Song',
      'pleaseEnterSongName': 'Please enter song name',
      'pleaseEnterMusicLink': 'Please enter a music link',
      'pleaseSelectMusicFile': 'Please select a music file',
      'storagePermissionRequired':
          'Storage permission is required to upload music files',
      'comingSoon': 'Coming soon!',
      'version': 'Version',
      'manageNotifications': 'Manage notification preferences',
      'done': 'Done',

      // YouTube Download
      'downloadForFasterPlayback': 'Download for faster playback?',
      'youtubeDownloadDescription':
          'Would you like to download this song to your device? This will make playback much faster next time.',
      'downloadingAudio': 'Downloading audio...',
      'downloadComplete': 'Download complete!',
      'downloadCompleteDescription':
          'The song will now play instantly from your device.',
      'downloadFailed': 'Download failed. Please try again later.',
      'downloadNow': 'Download Now',
      'skipForNow': 'Skip for now',

      // In-App Updates
      'updates': 'Updates',
      'checkForUpdates': 'Check for updates',
      'checkingForUpdates': 'Checking for updates...',
      'newVersionAvailable': 'New version available',
      'currentVersion': 'Current version',
      'youAreUpToDate': 'You are up to date',
      'updateAvailable': 'Update available',
      'whatsNew': "What's new",
      'later': 'Later',
      'updateNow': 'Update now',
      'downloading': 'Downloading...',
      'openingInstaller': 'Opening installer...',
      'retry': 'Retry',
      'newLabel': 'NEW',
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
