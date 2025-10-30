Backend module layout (modular, swappable implementations):

- interfaces/
  - analysis_repository.dart (save/fetch analyses)
  - storage_repository.dart (upload files)
  - vision_provider.dart (object detection)
  - generate_provider.dart (before/after generation)
- entities/
  - analysis.dart (domain entity separate from UI models)
- firebase/
  - firebase_analysis_repository.dart
  - firebase_storage_repository.dart
- fakes/
  - fake_analysis_repository.dart
  - fake_storage_repository.dart
  - fake_vision_provider.dart
  - fake_generate_provider.dart
- registry.dart (selects fake or firebase based on flags)

UI uses only interfaces from interfaces/ via Registry.

