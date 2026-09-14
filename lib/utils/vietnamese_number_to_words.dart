/// Bộ chuyển đổi số tiền thành chữ tiếng Việt chuẩn xác
class VietnameseNumberToWords {
  static const List<String> _digits = [
    'không',
    'một',
    'hai',
    'ba',
    'bốn',
    'năm',
    'sáu',
    'bảy',
    'tám',
    'chín',
  ];

  static const List<String> _units = [
    '',
    'nghìn',
    'triệu',
    'tỷ',
    'nghìn tỷ',
    'triệu tỷ',
  ];

  static String convert(num number) {
    int n = number.round();
    if (n == 0) return 'Không đồng chẵn.';
    if (n < 0) return 'Âm ${convert(-n)}';

    List<int> groups = [];
    int temp = n;
    while (temp > 0) {
      groups.add(temp % 1000);
      temp ~/= 1000;
    }

    List<String> groupWords = [];
    for (int i = groups.length - 1; i >= 0; i--) {
      int group = groups[i];
      if (group > 0) {
        String s = _readThreeDigits(group, i < groups.length - 1);
        groupWords.add('$s ${_units[i]}'.trim());
      }
    }

    String result = groupWords.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }
    return '$result đồng chẵn.';
  }

  static String _readThreeDigits(int n, bool full) {
    int c = n ~/ 100;
    int b = (n % 100) ~/ 10;
    int a = n % 10;

    String res = '';
    if (c > 0 || full) {
      res += '${_digits[c]} trăm ';
    }

    if (b > 1) {
      res += '${_digits[b]} mươi ';
      if (a == 1) {
        res += 'mốt ';
      } else if (a == 5) {
        res += 'lăm ';
      } else if (a > 0) {
        res += '${_digits[a]} ';
      }
    } else if (b == 1) {
      res += 'mười ';
      if (a == 1) {
        res += 'một ';
      } else if (a == 5) {
        res += 'lăm ';
      } else if (a > 0) {
        res += '${_digits[a]} ';
      }
    } else {
      if ((c > 0 || full) && a > 0) {
        res += 'lẻ ${_digits[a]} ';
      } else if (a > 0) {
        res += '${_digits[a]} ';
      }
    }

    return res.trim();
  }
}
