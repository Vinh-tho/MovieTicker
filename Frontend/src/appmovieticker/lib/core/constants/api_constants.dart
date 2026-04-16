import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static String get _host {
    if (_isAndroid) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get _scheme {
    if (_isAndroid || kIsWeb) {
      return 'http';
    }
    return 'https';
  }

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    return '$_scheme://$_host:7084/api';
  }

  static String get mediaBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride.replaceFirst(RegExp(r'/api/?$'), '');
    }
    return '$_scheme://$_host:7084';
  }

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String movieNowShowing = '/MoviePub/now-showing';
  static const String movieUpcoming = '/MoviePub/upcoming';
  static const String movieSpecial = '/MoviePub/special';
  static const String movieShowingAndUpcoming =
      '/MoviePub/showing-and-upcoming';
  static const String movieSearch = '/MoviePub/search';
  static const String movieDetail = '/MoviePub';
  static const String cinemaNearby = '/CinemaPub/nearby';
}
