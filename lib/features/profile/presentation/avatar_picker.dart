import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../incidents/presentation/photo_picker.dart' show PhotoSource;

/// Picks the profile photo. Behind an interface so the profile screen can be
/// tested without the platform plugin.
abstract interface class AvatarPicker {
  /// The chosen image, or null when the user backed out.
  Future<XFile?> pick(PhotoSource source);
}

class ImagePickerAvatarPicker implements AvatarPicker {
  final _picker = ImagePicker();

  @override
  Future<XFile?> pick(PhotoSource source) => _picker.pickImage(
    source: source == PhotoSource.camera
        ? ImageSource.camera
        : ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
}

final avatarPickerProvider = Provider<AvatarPicker>(
  (ref) => ImagePickerAvatarPicker(),
);
