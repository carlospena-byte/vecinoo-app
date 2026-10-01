import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PhotoSource { camera, gallery }

/// Picks photos from the camera or the gallery. Behind an interface so the
/// report flow can be tested without the platform plugin.
abstract interface class PhotoPicker {
  Future<List<XFile>> pick(PhotoSource source);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<List<XFile>> pick(PhotoSource source) async {
    switch (source) {
      case PhotoSource.camera:
        final shot = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
        return shot == null ? const [] : [shot];
      case PhotoSource.gallery:
        return _picker.pickMultiImage(imageQuality: 70);
    }
  }
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(),
);
