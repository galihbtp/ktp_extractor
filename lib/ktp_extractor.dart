
import 'ktp_extractor_platform_interface.dart';

class KtpExtractor {
  Future<String?> getPlatformVersion() {
    return KtpExtractorPlatform.instance.getPlatformVersion();
  }
}
