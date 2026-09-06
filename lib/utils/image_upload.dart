String imageMimeTypeForPath(String filePath) {
  final extension = filePath.toLowerCase().split('.').last;
  final mimeType = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heic',
  }[extension];

  if (mimeType == null) {
    throw ArgumentError('Unsupported image format: .$extension');
  }

  return mimeType;
}
