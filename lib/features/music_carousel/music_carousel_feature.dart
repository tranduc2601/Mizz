import 'package:flutter/material.dart';
import '../../core/feature_registry.dart';
import 'carousel_view_horizontal.dart';

/// Music Carousel Feature Module
///
/// This is the main 3D carousel feature that can be plugged in or removed
class MusicCarouselFeature extends FeatureModule {
  @override
  String get id => 'music_carousel';

  @override
  String get name => 'Music Carousel';

  @override
  String get description =>
      'Horizontal music card display with external controls';

  @override
  Widget? buildWidget(BuildContext context) {
    return const MusicCarouselView();
  }
}
