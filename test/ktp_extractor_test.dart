import 'package:flutter_test/flutter_test.dart';
import 'package:ktp_extractor/ktp_extractor.dart';
import 'package:ktp_extractor/ktp_extractor_platform_interface.dart';
import 'package:ktp_extractor/ktp_extractor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKtpExtractorPlatform
    with MockPlatformInterfaceMixin
    implements KtpExtractorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KtpExtractorPlatform initialPlatform = KtpExtractorPlatform.instance;

  test('$MethodChannelKtpExtractor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKtpExtractor>());
  });

  test('getPlatformVersion', () async {
    KtpExtractor ktpExtractorPlugin = KtpExtractor();
    MockKtpExtractorPlatform fakePlatform = MockKtpExtractorPlatform();
    KtpExtractorPlatform.instance = fakePlatform;

    expect(await ktpExtractorPlugin.getPlatformVersion(), '42');
  });
}
