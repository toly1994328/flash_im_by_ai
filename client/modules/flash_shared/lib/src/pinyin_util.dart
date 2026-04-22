import 'package:lpinyin/lpinyin.dart';

/// 拼音工具类 — 中文昵称到拼音首字母转换，用于通讯录字母索引
class PinyinUtil {
  PinyinUtil._();

  static const indexLetters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', '#',
  ];

  /// 获取昵称的首字母（大写 A-Z，非字母归入 #）
  static String getFirstLetter(String name) {
    if (name.isEmpty) return '#';
    final first = name[0];
    if (RegExp(r'[a-zA-Z]').hasMatch(first)) {
      return first.toUpperCase();
    }
    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(first)) {
      final pinyin = PinyinHelper.getFirstWordPinyin(name);
      if (pinyin.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(pinyin[0])) {
        return pinyin[0].toUpperCase();
      }
    }
    return '#';
  }

  /// 获取完整拼音（用于排序）
  static String getFullPinyin(String name) {
    if (name.isEmpty) return '';
    return PinyinHelper.getPinyinE(
      name, separator: '', format: PinyinFormat.WITHOUT_TONE,
    ).toLowerCase();
  }
}
