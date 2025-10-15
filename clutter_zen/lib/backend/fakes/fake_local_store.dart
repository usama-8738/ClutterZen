import '../interfaces/local_store.dart';

class FakeLocalStore implements ILocalStore {
  final Map<String, bool> _bools = {};

  @override
  Future<bool?> getBool(String key) async => _bools[key];

  @override
  Future<void> setBool(String key, bool value) async {
    _bools[key] = value;
  }
}


