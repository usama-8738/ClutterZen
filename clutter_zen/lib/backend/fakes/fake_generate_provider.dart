import '../interfaces/generate_provider.dart';

class FakeGenerateProvider implements IGenerateProvider {
  @override
  Future<String> generateOrganizedImage({required String imageUrl}) async {
    // Return the same image URL to simulate no-op generation
    return imageUrl;
  }
}


