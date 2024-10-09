import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ktp_extractor_platform_interface.dart';

/// An implementation of [KtpExtractorPlatform] that uses method channels.
class MethodChannelKtpExtractor extends KtpExtractorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ktp_extractor');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
