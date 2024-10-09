import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getAssetPath(String asset) async {
  final path = await getLocalPath(asset);
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(asset);
    await file
        .writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future<String> getLocalPath(String path) async {
  return '${(await getApplicationSupportDirectory()).path}/$path';
}

Future<File?> cropImage(File imageFile, DetectedObject object) async {
  final parse = await img.decodeImageFile(imageFile.absolute.path);
  if (parse == null) return null;
  final result = img.copyCrop(
    parse,
    x: object.boundingBox.left.toInt(),
    y: object.boundingBox.top.toInt(),
    width: (object.boundingBox.right - object.boundingBox.left).toInt(),
    height: (object.boundingBox.bottom - object.boundingBox.top).toInt(),
  );
  List<int> cropByte = [];
  cropByte = img.encodeJpg(result);
  final File imageFileCrop = await File(imageFile.absolute.path).writeAsBytes(cropByte);
  return imageFileCrop;
}
