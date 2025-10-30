import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/local_store.dart';

class SharedPrefsStore implements ILocalStore {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _get() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<bool?> getBool(String key) async {
    final p = await _get();
    return p.getBool(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final p = await _get();
    await p.setBool(key, value);
  }
}
