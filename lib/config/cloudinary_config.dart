class CloudinaryConfig {
  CloudinaryConfig._();

  static const cloudName = 'hcmiuujs';
  static const uploadPreset = 'campus_fix';

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}
