import 'package:flutter/material.dart';

/// Feature Registry - The core of the plug-and-play architecture
///
/// This registry allows features to be added or removed without breaking the app.
/// Simply remove a feature from the registry to "uninstall" it.
class FeatureRegistry {
  static final FeatureRegistry _instance = FeatureRegistry._internal();
  factory FeatureRegistry() => _instance;
  FeatureRegistry._internal();

  final Map<String, FeatureModule> _features = {};

  /// Register a feature module
  void register(FeatureModule feature) {
    _features[feature.id] = feature;
  }

  /// Unregister a feature module
  void unregister(String featureId) {
    _features.remove(featureId);
  }

  /// Get a specific feature
  FeatureModule? getFeature(String featureId) {
    return _features[featureId];
  }

  /// Get all registered features
  List<FeatureModule> getAllFeatures() {
    return _features.values.toList();
  }

  /// Check if a feature is registered
  bool hasFeature(String featureId) {
    return _features.containsKey(featureId);
  }

  /// Clear all features
  void clear() {
    _features.clear();
  }
}

/// Base class for all feature modules
///
/// Each feature must extend this class to be part of the system
abstract class FeatureModule {
  /// Unique identifier for the feature
  String get id;

  /// Display name of the feature
  String get name;

  /// Description of what the feature does
  String get description;

  /// Build the feature's main widget
  ///
  /// Returns null if the feature cannot be displayed
  Widget? buildWidget(BuildContext context);

  /// Optional: Initialize the feature
  /// This is called when the feature is registered
  Future<void> initialize() async {}

  /// Optional: Dispose resources
  void dispose() {}
}

/// Widget Manager - Safely renders features from the registry
///
/// This ensures that if a widget is missing or returns null,
/// the app doesn't crash
class FeatureWidget extends StatelessWidget {
  final String featureId;
  final Widget? fallback;

  const FeatureWidget({super.key, required this.featureId, this.fallback});

  @override
  Widget build(BuildContext context) {
    final registry = FeatureRegistry();
    final feature = registry.getFeature(featureId);

    if (feature == null) {
      // Feature not found - return fallback or empty container
      return fallback ?? const SizedBox.shrink();
    }

    try {
      final widget = feature.buildWidget(context);
      return widget ?? fallback ?? const SizedBox.shrink();
    } catch (e) {
      // Feature failed to build - safely handle error
      debugPrint('Error building feature $featureId: $e');
      return fallback ?? const SizedBox.shrink();
    }
  }
}

/// Conditional Feature Builder
///
/// Build different widgets based on feature availability
class ConditionalFeature extends StatelessWidget {
  final String featureId;
  final Widget Function(BuildContext context, FeatureModule feature) builder;
  final Widget? fallback;

  const ConditionalFeature({
    super.key,
    required this.featureId,
    required this.builder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final registry = FeatureRegistry();
    final feature = registry.getFeature(featureId);

    if (feature == null) {
      return fallback ?? const SizedBox.shrink();
    }

    try {
      return builder(context, feature);
    } catch (e) {
      debugPrint('Error in conditional feature $featureId: $e');
      return fallback ?? const SizedBox.shrink();
    }
  }
}
