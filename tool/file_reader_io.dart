import 'dart:io';

Future<String?> loadSeedJsonFromFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (_) {}
  return null;
}
