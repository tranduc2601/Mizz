import 'package:flutter/material.dart';
import '../../core/feature_registry.dart';
import 'user_profile_view.dart';

/// User Profile Feature Module
///
/// Manages user profile display and favorite songs
class UserProfileFeature extends FeatureModule {
  @override
  String get id => 'user_profile';

  @override
  String get name => 'User Profile';

  @override
  String get description => 'User profile and favorites management';

  @override
  Widget? buildWidget(BuildContext context) {
    return const UserProfileView();
  }
}
