class PhoneValidator {
  PhoneValidator._();

  static const Set<String> _vnPrefixes = {
    '032',
    '033',
    '034',
    '035',
    '036',
    '037',
    '038',
    '039',
    '070',
    '076',
    '077',
    '078',
    '079',
    '081',
    '082',
    '083',
    '084',
    '085',
    '088',
    '086',
    '096',
    '097',
    '098',
    '090',
    '091',
    '092',
    '093',
    '094',
    '095',
    '099',
  };

  static String? validateVietnamPhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Số điện thoại không được để trống';

    var s = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (s.startsWith('+84')) {
      s = '0' + s.substring(3);
    } else if (s.startsWith('84') && s.length > 8) {
      s = '0' + s.substring(2);
    }

    // keep only digits
    s = s.replaceAll(RegExp(r'[^0-9]'), '');

    if (s.length != 10 || !s.startsWith('0')) {
      return 'Số điện thoại không đúng định dạng (ví dụ: 0912345678)';
    }

    final prefix = s.substring(0, 3);
    if (!_vnPrefixes.contains(prefix)) {
      return 'Đầu số không hợp lệ hoặc không được hỗ trợ';
    }

    return null;
  }
}
