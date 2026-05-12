/// Environment config. In production, swap these to compile-time `--dart-define`
/// or a gitignored generated file. For now, fill in your Cloudinary creds below.
class Env {
  // Cloudinary
  // 1. Create a free account at https://cloudinary.com
  // 2. Copy your "Cloud name" from the dashboard.
  // 3. Settings -> Upload -> Add unsigned upload preset. Note the preset name.
  // 4. Recommended preset settings: folder=citideals, max file size=10MB,
  //    allowed formats=jpg,png,heic,webp, eager transformations for thumbnails.
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dku2rpjdk',
  );
  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'citideals_unsigned',
  );

  static bool get cloudinaryConfigured =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
}
