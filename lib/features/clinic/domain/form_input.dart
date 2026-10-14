import 'package:flutter/services.dart';

final digitsOnly = FilteringTextInputFormatter.digitsOnly;

final phoneFormatters = <TextInputFormatter>[
  digitsOnly,
  LengthLimitingTextInputFormatter(10),
];

final yearsFormatters = <TextInputFormatter>[
  digitsOnly,
  LengthLimitingTextInputFormatter(2),
];

final feeFormatters = <TextInputFormatter>[
  digitsOnly,
  LengthLimitingTextInputFormatter(6),
];

final personNameFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'\-]")),
  const CapitalizeWordsFormatter(),
];

final titleFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 .,+\-]')),
  const CapitalizeWordsFormatter(),
];

final sentenceFormatters = <TextInputFormatter>[
  const CapitalizeSentencesFormatter(),
];

final emailFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.deny(RegExp(r'\s')),
  const LowercaseFormatter(),
];

class CapitalizeWordsFormatter extends TextInputFormatter {
  const CapitalizeWordsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: capitalizeWords(newValue.text));
  }
}

class CapitalizeSentencesFormatter extends TextInputFormatter {
  const CapitalizeSentencesFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: capitalizeSentences(newValue.text));
  }
}

class LowercaseFormatter extends TextInputFormatter {
  const LowercaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}

String capitalizeWords(String input) {
  final out = StringBuffer();
  var start = true;
  for (final code in input.runes) {
    final char = String.fromCharCode(code);
    final letter = RegExp(r'[A-Za-z]').hasMatch(char);
    if (start && letter) {
      out.write(char.toUpperCase());
      start = false;
    } else {
      out.write(char);
      start = char == ' ' || char == '-' || char == '\n';
    }
  }
  return out.toString();
}

String capitalizeSentences(String input) {
  final out = StringBuffer();
  var start = true;
  String? previous;
  for (final code in input.runes) {
    final char = String.fromCharCode(code);
    final letter = RegExp(r'[A-Za-z]').hasMatch(char);
    final afterBreak = previous == '.' || previous == '!' || previous == '?';
    if ((start || afterBreak) && letter) {
      out.write(char.toUpperCase());
      start = false;
    } else {
      out.write(char);
      if (char == '\n') start = true;
    }
    previous = char;
  }
  return out.toString();
}
