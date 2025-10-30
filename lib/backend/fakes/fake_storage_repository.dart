import 'dart:typed_data';
import '../interfaces/storage_repository.dart';

class FakeStorageRepository implements IStorageRepository {
  @override
  Future<String> uploadBytes(
      {required String path,
      required Uint8List data,
      String? contentType}) async {
    // Return a data URL placeholder
    return 'data:$contentType;base64,${data.length}';
  }
}
