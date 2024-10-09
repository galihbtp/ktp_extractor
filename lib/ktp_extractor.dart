import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ktp_extractor/utils/ext.dart';
import 'package:ktp_extractor/utils/utils.dart';

import 'models/ktp_model.dart';

export 'models/ktp_model.dart';

/// A utility class for extracting information from KTP (Indonesian ID card) images.
class KtpExtractor {
  static const String _genderKey = 'gender';
  static const String _religionKey = 'religion';
  static const String _maritalKey = 'marital';
  static const String _nationalityKey = 'nationality';

  /// A map of expected words for certain fields to assist in data correction.
  static final Map<String, List<String>> _expectedWords = {
    _genderKey: ['LAKI-LAKI', 'PEREMPUAN'],
    _religionKey: ['ISLAM', 'KRISTEN', 'KATOLIK', 'HINDU', 'BUDDHA', 'KHONGHUCU'],
    _maritalKey: ['KAWIN', 'BELUM KAWIN'],
    _nationalityKey: ['WNI', 'WNA'],
  };

  /// Crops the KTP area from the provided image using object detection.
  ///
  /// This method uses a custom TensorFlow Lite model to detect and crop the KTP
  /// (Indonesian ID card) area from the given image. It returns a [File] containing
  /// the cropped image or `null` if no KTP is detected.
  ///
  /// [imageFile]: The image file containing the KTP.
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

    // Iterate over detected objects to find the KTP.
    for (final object in result) {
      if (kDebugMode) {
        print('Object found: ${object.labels.map((e) => e.text)}');
      }
      if (object.labels.firstOrNull?.text == "Driver's license") {
        // Crop the image to the detected KTP area.
        imageCropped = await cropImage(File(inputImage.filePath!), object);
        break;
      }
    }

    await detector.close();
    return imageCropped;
  }

  /// Extracts KTP information from the provided image file.
  ///
  /// This method performs text recognition on the image to extract
  /// various fields from the KTP, such as NIK, name, birth date, etc.
  ///
  /// [imageFile]: The image file of the KTP.
  static Future<KtpModel> extractKtp(File imageFile) async {
    final TextRecognizer recognizer = TextRecognizer();
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await recognizer.processImage(inputImage);
    await recognizer.close();

    return extractFromOcr(recognizedText);
  }

  /// Extracts KTP information from recognized text.
  ///
  /// This method parses the recognized text from OCR to extract
  /// KTP fields and returns a [KtpModel] containing the extracted data.
  ///
  /// [recognizedText]: The recognized text from OCR.
  static KtpModel extractFromOcr(RecognizedText recognizedText) {
    String? nik;
    String? name;
    String? placeBirth;
    String? birthDay;
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
      print('Result text: ${recognizedText.text}');
    }

    // Iterate over text blocks and lines to extract information.
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final String text = line.text;

        // Extract NIK (Identity Number).
        if (nik == null && text.filterNumbersOnly().length == 16) {
          nik = text.filterNumbersOnly();
          if (kDebugMode) {
            print('NIK Found: ${line.text}');
            print('NIK Filtered: $nik');
          }
        }
        if (nik == null && text.toLowerCase().startsWith('nik')) {
          final lineText = recognizedText.findAndClean(line, 'NIK');
          nik = lineText?.filterNumbersOnly().removeAlphabet();
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
            print('Line Text Filtered: $nik');
          }
        }

        // Extract Name.
        if (text.toLowerCase().startsWith('nama')) {
          final lineText = recognizedText.findAndClean(line, 'nama')?.filterNumberToAlphabet();
          name = lineText;
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract Place and Date of Birth.
        if (text.toLowerCase().contains(RegExp('tempat')) &&
            text.toLowerCase().contains(RegExp('lahir'))) {
          if (kDebugMode) {
            print('Text: $text');
          }
          String? lineText = recognizedText.findAndClean(line, 'tempat/tgl lahir');
          if (lineText != null) {
            lineText = lineText.cleanse('tempat');
            lineText = lineText.cleanse('tgl lahir');
            if (lineText.split('/').isNotEmpty) {
              lineText = lineText.replaceAll('/', '');
            }
          }
          final List<String> splitBirth = lineText?.split(',') ?? [];
          if (kDebugMode) {
            print('Split Place of Birth: $splitBirth');
          }
          if (splitBirth.isNotEmpty) {
            placeBirth = splitBirth[0].filterNumberToAlphabet();
            if (splitBirth.length > 1) {
              birthDay = splitBirth[1].filterAlphabetToNumber();
            }
          }
          if (kDebugMode) {
            print('Line Text: $lineText');
          }
        }

        // Extract Gender.
        if (text.toLowerCase().startsWith('jenis kelamin')) {
          final lineText = recognizedText
              .findAndClean(line, 'jenis kelamin')
              ?.filterNumberToAlphabet()
              .correctWord(_expectedWords[_genderKey]!);
          gender = lineText;
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract Address.
        if (text.toLowerCase().startsWith('alamat')) {
          final lineText = recognizedText.findAndClean(line, 'alamat');
          address = lineText;
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract RT/RW (Neighborhood and Hamlet numbers).
        if (text.toLowerCase().contains(RegExp('rt')) &&
            text.toLowerCase().contains(RegExp('rw'))) {
          if (kDebugMode) {
            print('Text: $text');
          }
          String? lineText = recognizedText.findAndClean(line, 'RTRW');
          if (lineText != null) {
            lineText = lineText.cleanse('rt');
            lineText = lineText.cleanse('rw');
            if (lineText.split('/').length == 2) {
              lineText = lineText.replaceFirst('/', '');
            }
          }
          final List<String> splitRtRw =
              lineText?.filterAlphabetToNumber().removeAlphabet().split('/') ?? [];
          if (kDebugMode) {
            print('Split RT/RW: $splitRtRw');
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
            print('Line Text: $lineText');
          }
        }

        // Extract Sub-District.
        if (text.toLowerCase().contains(RegExp('desa'))) {
          final lineText = recognizedText.findAndClean(line, 'kel/desa');
          subDistrict = lineText?.filterNumberToAlphabet();
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract District.
        if (text.toLowerCase().startsWith('kecamatan')) {
          final lineText = recognizedText.findAndClean(line, 'kecamatan');
          district = lineText?.filterNumberToAlphabet();
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract Religion.
        if (text.toLowerCase().startsWith('agama')) {
          final lineText = recognizedText.findAndClean(line, 'agama');
          religion = lineText?.filterNumberToAlphabet().correctWord(_expectedWords[_religionKey]!);
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract Marital Status.
        if (text.toLowerCase().startsWith('status perkawinan')) {
          final lineText = recognizedText.findAndClean(line, 'status perkawinan');
          marital = lineText?.filterNumberToAlphabet().correctWord(_expectedWords[_maritalKey]!);
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract Occupation.
        if (text.toLowerCase().startsWith('pekerjaan')) {
          final lineText = recognizedText.findAndClean(line, 'pekerjaan');
          occupation = lineText?.filterNumberToAlphabet();
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract Nationality.
        if (text.toLowerCase().startsWith('kewarganegaraan')) {
          final lineText = recognizedText.findAndClean(line, 'kewarganegaraan');
          nationality =
              lineText?.filterNumberToAlphabet().correctWord(_expectedWords[_nationalityKey]!);
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }

        // Extract Valid Until date.
        if (text.toLowerCase().startsWith('berlaku hingga')) {
          final lineText = recognizedText.findAndClean(line, 'berlaku hingga');
          validUntil = lineText?.filterNumberToAlphabet();
          if (kDebugMode) {
            print('Text: $text');
            print('Line Text: $lineText');
          }
        }
      }
    }

    if (kDebugMode) {
      print('========================================');
      print('=============== RESULT =================');
      print('NIK: $nik');
      print('Name: $name');
      print('Birth Day: $birthDay');
      print('Place of Birth: $placeBirth');
      print('Gender: $gender');
      print('Address: $address');
      print('RT/RW: $rt / $rw');
      print('Sub-District: $subDistrict');
      print('District: $district');
      print('Religion: $religion');
      print('Marital Status: $marital');
      print('Occupation: $occupation');
      print('Nationality: $nationality');
      print('Valid Until: $validUntil');
      print('============= END RESULT ===============');
      print('========================================');
    }

    // Return a KtpModel containing the extracted information.
    return KtpModel(
      address: address,
      district: district,
      gender: gender,
      marital: marital,
      name: name,
      birthDay: birthDay,
      placeBirth: placeBirth,
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
