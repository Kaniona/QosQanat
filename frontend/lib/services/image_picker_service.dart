import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Профиль суретін таңдау нәтижесі.
enum PickPhotoStatus { success, cancelled, failed }

class PickPhotoResult {
  const PickPhotoResult(this.status, [this.path]);

  final PickPhotoStatus status;
  final String? path;
}

/// Профиль суретін телефоннан таңдап, локальді сақтау.
class ImagePickerService {
  ImagePickerService._();
  static final ImagePickerService instance = ImagePickerService._();

  final ImagePicker _picker = ImagePicker();

  /// Галереядан сурет таңдап, қосымшаның папкасына көшіреді.
  /// [previousPath] берілсе, ескі сурет файлы өшіріледі (диск тазалығы).
  Future<PickPhotoResult> pickProfilePhoto(
    String userId, {
    String? previousPath,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) {
        return const PickPhotoResult(PickPhotoStatus.cancelled);
      }

      final dir = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last;
      final target = File(
        '${dir.path}/profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await File(picked.path).copy(target.path);

      if (previousPath != null) {
        try {
          final old = File(previousPath);
          if (await old.exists()) await old.delete();
        } catch (_) {
          // Ескі файл өшпесе де жаңа сурет жұмыс істей береді.
        }
      }
      return PickPhotoResult(PickPhotoStatus.success, target.path);
    } catch (_) {
      return const PickPhotoResult(PickPhotoStatus.failed);
    }
  }
}
