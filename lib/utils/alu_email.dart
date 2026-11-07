const kAluEmailDomains = ['alustudent.com', 'alu.edu', 'aluedu.com'];
const kAluStaffEmailDomain = 'aluedu.com';

final _emailPattern = RegExp(
  r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@"
  r'(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$',
);

bool isValidEmail(String? email) {
  final normalized = email?.trim();
  return normalized != null && _emailPattern.hasMatch(normalized);
}

bool isAluEmail(String? email) {
  final normalized = email?.trim().toLowerCase();
  if (normalized == null || !isValidEmail(normalized)) return false;
  final atIndex = normalized.lastIndexOf('@');
  return kAluEmailDomains.contains(normalized.substring(atIndex + 1));
}

bool isAluStaffEmail(String? email) {
  final normalized = email?.trim().toLowerCase();
  if (normalized == null || !isValidEmail(normalized)) return false;
  return normalized.endsWith('@$kAluStaffEmailDomain');
}
