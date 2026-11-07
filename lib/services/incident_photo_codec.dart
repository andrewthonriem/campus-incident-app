import 'dart:typed_data';

import 'package:image/image.dart' as img;

const maxIncidentPhotoBytes = 700 * 1024;
const _maxPhotoSide = 1280;
const _minPhotoSide = 256;

class CompressedIncidentPhoto {
  const CompressedIncidentPhoto({
    required this.bytes,
    required this.thumbnail,
  });

  final Uint8List bytes;
  final Uint8List thumbnail;
}

CompressedIncidentPhoto compressIncidentPhoto(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    throw const FormatException('The selected file is not a supported image.');
  }

  var image = _resizeToMaxSide(decoded, _maxPhotoSide);
  Uint8List? compressed;
  while (true) {
    for (final quality in [80, 70, 60, 50, 40]) {
      final candidate =
          Uint8List.fromList(img.encodeJpg(image, quality: quality));
      if (candidate.lengthInBytes <= maxIncidentPhotoBytes) {
        compressed = candidate;
        break;
      }
    }
    if (compressed != null) break;

    final longestSide = image.width > image.height ? image.width : image.height;
    if (longestSide <= _minPhotoSide) {
      throw StateError('The selected photo could not be compressed enough.');
    }
    image = _resizeToMaxSide(image, (longestSide * 0.75).round());
  }

  final thumbnailImage = _resizeToMaxSide(image, 256);
  final thumbnail = Uint8List.fromList(
    img.encodeJpg(thumbnailImage, quality: 65),
  );
  return CompressedIncidentPhoto(bytes: compressed, thumbnail: thumbnail);
}

img.Image _resizeToMaxSide(img.Image image, int maxSide) {
  final longestSide = image.width > image.height ? image.width : image.height;
  if (longestSide <= maxSide) return image;

  if (image.width >= image.height) {
    return img.copyResize(image, width: maxSide);
  }
  return img.copyResize(image, height: maxSide);
}
