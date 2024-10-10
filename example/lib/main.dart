import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ktp_extractor/ktp_extractor.dart';
import 'package:ktp_extractor/utils/utils.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ImagePicker? _imagePicker;
  File? _image;
  KtpModel? _ktpModel;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: ListView(
        children: [
          if (_image != null) ...[
            Image.file(_image!),
            const SizedBox(
              height: 12,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _getImageAsset,
              child: const Text('From Assets'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              child: const Text('From Gallery'),
              onPressed: () => _getImage(ImageSource.gallery),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              child: const Text('Take a picture'),
              onPressed: () => _getImage(ImageSource.camera),
            ),
          ),
          if (_ktpModel != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provinsi : ${_ktpModel!.province}',
                    maxLines: null,
                  ),
                  Text(
                    'Kota / Kabupaten : ${_ktpModel!.city}',
                    maxLines: null,
                  ),
                  Text(
                    'NIK : ${_ktpModel!.nik}',
                    maxLines: null,
                  ),
                  Text(
                    'Nama : ${_ktpModel!.name}',
                    maxLines: null,
                  ),
                  Text(
                    'Tempat Lahir : ${_ktpModel!.placeBirth}',
                    maxLines: null,
                  ),
                  Text(
                    'Tanggal Lahir : ${_ktpModel!.birthDay}',
                    maxLines: null,
                  ),
                  Text(
                    'Alamat : ${_ktpModel!.address}',
                    maxLines: null,
                  ),
                  Text(
                    '\t\t\tRT / RW : ${_ktpModel!.rt} / ${_ktpModel!.rw}',
                    maxLines: null,
                  ),
                  Text(
                    '\t\t\tKel/Desa : ${_ktpModel!.subDistrict}',
                    maxLines: null,
                  ),
                  Text(
                    '\t\t\tKecamatan : ${_ktpModel!.district}',
                    maxLines: null,
                  ),
                  Text(
                    'Agama : ${_ktpModel!.religion}',
                    maxLines: null,
                  ),
                  Text(
                    'Status Perkawinan : ${_ktpModel!.marital}',
                    maxLines: null,
                  ),
                  Text(
                    'Pekerjaan : ${_ktpModel!.occupation}',
                    maxLines: null,
                  ),
                  Text(
                    'Kewarganegaraan : ${_ktpModel!.nationality}',
                    maxLines: null,
                  ),
                  Text(
                    'Berlaku Hingga : ${_ktpModel!.validUntil}',
                    maxLines: null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _ktpModel = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      _processFile(pickedFile.path);
    }
  }

  Future _getImageAsset() async {
    setState(() {
      _image = null;
      _ktpModel = null;
    });
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final assets = manifestMap.keys
        .where((String key) => key.contains('images/'))
        .where((String key) =>
            key.contains('.jpg') ||
            key.contains('.jpeg') ||
            key.contains('.png') ||
            key.contains('.webp'))
        .toList();

    showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select image',
                    style: TextStyle(fontSize: 20),
                  ),
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final path in assets)
                            GestureDetector(
                              onTap: () async {
                                Navigator.of(context).pop();
                                _processFile(await getAssetPath(path));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(path),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ],
              ),
            ),
          );
        });
  }

  Future _processFile(String path) async {
    _image = await KtpExtractor.cropImageForKtp(File(path));
    _image ??= File(path);
    _ktpModel = await KtpExtractor.extractKtp(_image!);
    setState(() {});
    // _path = path;
    // final inputImage = InputImage.fromFilePath(path);
    // widget.onImage(inputImage);
  }
}
