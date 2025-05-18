import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:string_similarity/string_similarity.dart';

extension TextLineExt on RecognizedText {
  String? findAndClean(TextLine line, String key) {
    if (line.elements.length > key.split(" ").length) {
      return line.text.cleanse(key);
    } else {
      return findInline(line)?.text.cleanse(key);
    }
  }

  TextLine? findInline(TextLine line) {
    final double top = line.boundingBox.top;
    final double bottom = line.boundingBox.bottom;

    final List<TextLine> result = [];

    for (final block in blocks) {
      for (final textLine in block.lines) {
        final centerY =
            (textLine.boundingBox.bottom + textLine.boundingBox.top) / 2;

        if (centerY >= top && centerY <= bottom && textLine.text != line.text) {
          result.add(textLine);
        }
      }
    }

    if (result.isEmpty) return null;

    // Find the line with the minimum left position
    return result.reduce((a, b) {
      final leftA = a.boundingBox.left;
      final leftB = b.boundingBox.left;
      return leftA < leftB ? a : b;
    });
  }
}

extension StringExtension on String {
  String filterNumbersOnly() {
    final String corrected = replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('B', '8')
        .replaceAll('b', '6')
        .replaceAll('S', '5')
        .replaceAll('Z', '2')
        .replaceAll('z', '2')
        .replaceAll('D', '0')
        .replaceAll('A', '4')
        .replaceAll('e', '2')
        .replaceAll('L', '6')
        .replaceAll('T', '7');

    return corrected.removeAlphabet();
  }

  String removeAlphabet() {
    return replaceAll(RegExp(r'[^0-9]'), '');
  }

  String cleanse(String text, {bool ignoreCase = true}) {
    String cleaned = this;

    // Replace text with an empty string, respecting case sensitivity
    if (ignoreCase) {
      cleaned = cleaned.replaceAll(RegExp(text, caseSensitive: false), '');
    } else {
      cleaned = cleaned.replaceAll(text, '');
    }

    // Remove colons and trim whitespace
    cleaned = cleaned.replaceAll(':', '').trim();

    return cleaned;
  }

  String filterNumberToAlphabet() {
    return replaceAll('0', 'O')
        .replaceAll('1', 'I')
        .replaceAll('4', 'A')
        .replaceAll('5', 'S')
        .replaceAll('7', 'T')
        .replaceAll('8', 'B')
        .replaceAll('9', 'B');
  }

  String filterAlphabetToNumber() {
    return replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('B', '8')
        .replaceAll('b', '6')
        .replaceAll('S', '5')
        .replaceAll('Z', '2')
        .replaceAll('z', '2')
        .replaceAll('D', '0')
        .replaceAll('A', '4')
        .replaceAll('e', '2')
        .replaceAll('L', '6')
        .replaceAll('T', '7');
  }

  String? correctWord(List<String> expectedWords, {bool safetyBack = false}) {
    /// define zero initial and increase when add similar from word
    /// this is same with confidence in AI
    double highestSimilarity = 0.0;
    String closestWord = this;

    for (final word in expectedWords) {
      final double similarity = similarityTo(word);
      if (similarity > highestSimilarity) {
        highestSimilarity = similarity;
        closestWord = word;
      }
    }

    if (!safetyBack && highestSimilarity < 0.5) {
      return null;
    }
    return closestWord;
  }
}
