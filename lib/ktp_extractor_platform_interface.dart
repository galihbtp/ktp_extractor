import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ktp_extractor_method_channel.dart';

abstract class KtpExtractorPlatform extends PlatformInterface {
  /// Constructs a KtpExtractorPlatform.
  KtpExtractorPlatform() : super(token: _token);

  static final Object _token = Object();

  static KtpExtractorPlatform _instance = MethodChannelKtpExtractor();

  /// The default instance of [KtpExtractorPlatform] to use.
  ///
  /// Defaults to [MethodChannelKtpExtractor].
  static KtpExtractorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KtpExtractorPlatform] when
  /// they register themselves.
  static set instance(KtpExtractorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
