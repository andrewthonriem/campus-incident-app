import 'alu_email.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!isValidEmail(v)) return 'Enter a valid email address';
    return null;
  }

  static String? aluEmail(String? value) {
    final emailError = email(value);
    if (emailError != null) return emailError;
    if (!isAluEmail(value)) {
      return 'Use your ALU email (@alustudent.com, @alu.edu, or @aluedu.com)';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Please confirm your password';
      if (value != original()) return 'Passwords do not match';
      return null;
    };
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please add a short title';
    if (v.length < 5) return 'Title must be at least 5 characters';
    if (v.length > 80) return 'Title must be 80 characters or fewer';
    return null;
  }

  static String? description(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please describe the issue';
    if (v.length < 15) return 'Add a bit more detail (at least 15 characters)';
    if (v.length > 1000) return 'Description must be 1000 characters or fewer';
    return null;
  }

  static String? location(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Location is required';
    return null;
  }
}
