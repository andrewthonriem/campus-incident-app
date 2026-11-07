import 'dart:typed_data';

import 'package:campus_incident_app/services/incident_photo_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('compresses report photo and thumbnail within Firestore limits', () {
    final source = img.Image(width: 1600, height: 1200);
    final input = Uint8List.fromList(img.encodePng(source));

    final compressed = compressIncidentPhoto(input);
    final photo = img.decodeImage(compressed.bytes);
    final thumbnail = img.decodeImage(compressed.thumbnail);

    expect(compressed.bytes.lengthInBytes,
        lessThanOrEqualTo(maxIncidentPhotoBytes));
    expect(photo, isNotNull);
    expect(photo!.width, lessThanOrEqualTo(1280));
    expect(photo.height, lessThanOrEqualTo(1280));
    expect(thumbnail, isNotNull);
    expect(thumbnail!.width, lessThanOrEqualTo(256));
    expect(thumbnail.height, lessThanOrEqualTo(256));
  });

  test('rejects data that is not an image', () {
    expect(
      () => compressIncidentPhoto(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
