import 'package:flutter/material.dart';

class RTLSupport {
  static bool isRTL(String? language) {
    return language == 'ar';
  }

  static TextDirection getTextDirection(String? language) {
    return isRTL(language) ? TextDirection.rtl : TextDirection.ltr;
  }

  static Alignment getAlignment(String? language, {bool reverse = false}) {
    if (isRTL(language)) {
      return reverse ? Alignment.centerRight : Alignment.centerLeft;
    }
    return reverse ? Alignment.centerLeft : Alignment.centerRight;
  }

  static CrossAxisAlignment getCrossAxisAlignment(String? language) {
    return isRTL(language) 
        ? CrossAxisAlignment.end 
        : CrossAxisAlignment.start;
  }

  static MainAxisAlignment getMainAxisAlignment(String? language) {
    return isRTL(language) 
        ? MainAxisAlignment.end 
        : MainAxisAlignment.start;
  }
}
