import 'dart:typed_data';

abstract class IStorageRepository {
  Future<String> uploadBytes(
      {required String path, required Uint8List data, String? contentType});
}
