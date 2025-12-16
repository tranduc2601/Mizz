import 'package:flutter/material.dart';
import '../features/auth/auth_service.dart';

/// Global Auth Service Provider
class AuthProvider extends InheritedNotifier<AuthService> {
  const AuthProvider({
    super.key,
    required AuthService authService,
    required super.child,
  }) : super(notifier: authService);

  static AuthService of(BuildContext context) {
    final AuthProvider? provider = context
        .dependOnInheritedWidgetOfExactType<AuthProvider>();
    assert(provider != null, 'No AuthProvider found in context');
    return provider!.notifier!;
  }

  static AuthService? maybeOf(BuildContext context) {
    final AuthProvider? provider = context
        .dependOnInheritedWidgetOfExactType<AuthProvider>();
    return provider?.notifier;
  }
}
