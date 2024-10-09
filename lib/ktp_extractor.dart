import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ktp_extractor/utils/ext.dart';
import 'package:ktp_extractor/utils/utils.dart';

import 'models/ktp_model.dart';

export 'models/ktp_model.dart';

class KtpExtractor {
  static const String _genderKey = 'gender';
  static const String _religionKey = 'religion';
  static const String _maritalKey = 'marital';
  static const String _nationalityKey = 'nationality';
  static final Map<String, List<String>> _expectedWords = {
    _genderKey: ['LAKI-LAKI', 'PEREMPUAN'],
    _religionKey: ['ISLAM', 'KRISTEN', 'KATOLIK', 'HINDU', 'BUDDHA', 'KHONGHUCU'],
    _maritalKey: ['KAWIN', 'BELUM KAWIN'],
    _nationalityKey: ['WNI', 'WNA'],
  };

  static Future<File?> cropImageForKtp(File imageFile) async {
    final modelPath =
        await getAssetPath('packages/ktp_extractor/assets/custom_models/object_labeler.tflite');
    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.single,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );
    final ObjectDetector detector = ObjectDetector(options: options);
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final result = await detector.processImage(inputImage);

    File? imageCropped;

    for (final object in result) {
      if (kDebugMode) {
        print('object found : ${object.labels.map((e) => e.text)}');
      }
      if (object.labels.firstOrNull?.text == "Driver's license") {
        imageCropped = await cropImage(File(inputImage.filePath!), object);
        break;
      }
    }

    await detector.close();
    return imageCropped;
  }

  static Future<KtpModel> extractKtp(File imageFile) async {
    final TextRecognizer recognizer = TextRecognizer();
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await recognizer.processImage(inputImage);
    await recognizer.close();

    return extractFromOcr(recognizedText);
  }

  static KtpModel extractFromOcr(RecognizedText recognizedText) {
    String? nik;
    String? name;
    String? gender;
    String? address;
    String? rt;
    String? rw;
    String? subDistrict;
    String? district;
    String? religion;
    String? marital;
    String? occupation;
    String? nationality;
    String? validUntil;

    if (kDebugMode) {
      print('result text : ${recognizedText.text}');
    }

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final String text = line.text;
        // switch (line.text.toLowerCase()) {
        //   case 'nik':
        //     {
        if (nik == null && text.filterNumbersOnly().length == 16) {
          nik = text.filterNumbersOnly();
          if (kDebugMode) {
            print('Nik Found : ${line.text}');
            print('Nik Found filtered : $nik');
          }
        }
        if (nik == null && text.toLowerCase().startsWith('nik')) {
          final lineText = recognizedText.findAndClean(line, 'NIK');
          nik = lineText?.filterNumbersOnly().removeAlphabet();
          if (kDebugMode) {
            print('text : $text');
            print('lineText : $lineText');
            print('lineText Filtered : $nik');
          }
        }
        if (text.toLowerCase().startsWith('nama')) {
          final lineText = recognizedText.findAndClean(line, 'nama')?.filterNumberToAlphabet();
          name = lineText;
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().startsWith('jenis kelamin')) {
          final lineText = recognizedText
              .findAndClean(line, 'jenis kelamin')
              ?.filterNumberToAlphabet()
              .correctWord(_expectedWords[_genderKey]!);
          gender = lineText;
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().startsWith('alamat')) {
          final lineText = recognizedText.findAndClean(line, 'alamat');
          address = lineText;
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().contains(RegExp('rt')) &&
            text.toLowerCase().contains(RegExp('rw'))) {
          if (kDebugMode) {
            print('text ; $text');
          }
          String? lineText = recognizedText.findAndClean(line, 'RTRW');
          if (lineText != null) {
            lineText = lineText.cleanse('rt');
            lineText = lineText.cleanse('rw');
            if (lineText.split('/').length == 2) {
              lineText.replaceFirst('/', '');
            }
          }
          final List<String> splitRtRw =
              lineText?.filterAlphabetToNumber().removeAlphabet().split('/') ?? [];
          if (kDebugMode) {
            print('split rt rw : $splitRtRw');
          }
          if (splitRtRw.isNotEmpty) {
            rt = splitRtRw[0];
            if (splitRtRw.length > 1) {
              rw = splitRtRw[1];
            } else {
              if (rt.length > 3) {
                rw = rt.substring(3);
                rt = rt.substring(0, 3);
              }
            }
          }
          if (kDebugMode) {
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().contains(RegExp('desa'))) {
          final lineText = recognizedText.findAndClean(line, 'kel/desa');
          subDistrict = lineText?.filterNumberToAlphabet();
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().startsWith('kecamatan')) {
          final lineText = recognizedText.findAndClean(line, 'kecamatan');
          district = lineText?.filterNumberToAlphabet();
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().startsWith('agama')) {
          final lineText = recognizedText.findAndClean(line, 'agama');
          religion = lineText?.filterNumberToAlphabet().correctWord(_expectedWords[_religionKey]!);
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().startsWith('status perkawinan')) {
          final lineText = recognizedText.findAndClean(line, 'status perkawinan');
          marital = lineText?.filterNumberToAlphabet().correctWord(_expectedWords[_maritalKey]!);
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().startsWith('pekerjaan')) {
          final lineText = recognizedText.findAndClean(line, 'pekerjaan');
          occupation = lineText?.filterNumberToAlphabet();
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().startsWith('kewarganegaraan')) {
          final lineText = recognizedText.findAndClean(line, 'kewarganegaraan');
          nationality =
              lineText?.filterNumberToAlphabet().correctWord(_expectedWords[_nationalityKey]!);
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
        if (text.toLowerCase().startsWith('berlaku hingga')) {
          final lineText = recognizedText.findAndClean(line, 'berlaku hingga');
          validUntil = lineText?.filterNumberToAlphabet();
          if (kDebugMode) {
            print('text ; $text');
            print('lineText text : ${lineText}');
          }
        }
      }
    }
    if (kDebugMode) {
      print('========================================');

      print('=============== RESULT =================');
      print('NIK : $nik');
      print('Name : $name');
      print('Gender : $gender');
      print('address : $address');
      print('RT/RW : $rt / $rw');
      print('SubDistrict : $subDistrict');
      print('District : $district');
      print('Religion : $religion');
      print('Marital : $marital');
      print('Occupation : $occupation');
      print('Nationality : $nationality');
      print('Valid Until : $validUntil');
      print('============= END RESULT ===============');
      print('========================================');
    }
    return KtpModel(
      address: address,
      district: district,
      gender: gender,
      marital: marital,
      name: name,
      nationality: nationality,
      nik: nik,
      occupation: occupation,
      religion: religion,
      rt: rt,
      rw: rw,
      subDistrict: subDistrict,
      validUntil: validUntil,
    );
  }
}
