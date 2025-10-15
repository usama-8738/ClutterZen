import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../interfaces/storage_repository.dart';

class FirebaseStorageRepository implements IStorageRepository {
  FirebaseStorageRepository(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> uploadBytes({required String path, required Uint8List data, String? contentType}) async {
    final ref = _storage.ref(path);
    final meta = SettableMetadata(contentType: contentType);
    await ref.putData(data, meta);
    return ref.getDownloadURL();
  }
}


