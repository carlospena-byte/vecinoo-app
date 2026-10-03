// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/env/env.dart';
import 'package:gates_app/core/supabase/supabase_providers.dart';
import 'package:gates_app/features/amenities/data/supabase_amenities_repository.dart';
import 'package:gates_app/features/amenities/presentation/amenities_controller.dart';
import 'package:gates_app/features/auth/data/supabase_auth_repository.dart';
import 'package:gates_app/features/auth/presentation/auth_controller.dart';
import 'package:gates_app/features/incidents/data/supabase_incidents_repository.dart';
import 'package:gates_app/features/incidents/presentation/incidents_controller.dart';
import 'package:gates_app/features/incidents/presentation/photo_picker.dart';
import 'package:gates_app/features/profile/data/supabase_profile_repository.dart';
import 'package:gates_app/features/profile/presentation/profile_controller.dart';
import 'package:gates_app/features/session/data/supabase_session_repository.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/data/providers_catalog_repository.dart';
import 'package:gates_app/features/visits/data/supabase_visits_repository.dart';
import 'package:gates_app/features/visits/presentation/providers_catalog_controller.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeImagePicker extends ImagePickerPlatform {
  ImageSource? lastSource;
  int? lastQuality;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    lastSource = source;
    lastQuality = options.imageQuality;
    return XFile.fromData(Uint8List.fromList([1]), path: 'shot.jpg');
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    lastQuality = options.imageOptions.imageQuality;
    return [
      XFile.fromData(Uint8List.fromList([1]), path: 'a.jpg'),
      XFile.fromData(Uint8List.fromList([2]), path: 'b.jpg'),
    ];
  }
}

void main() {
  test('every repository provider builds its Supabase implementation', () {
    final client = SupabaseClient('http://127.0.0.1:1', 'anon-key');
    final container = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(client)],
    );
    addTearDown(() {
      container.dispose();
      client.dispose();
    });

    expect(
      container.read(visitsRepositoryProvider),
      isA<SupabaseVisitsRepository>(),
    );
    expect(
      container.read(providersCatalogRepositoryProvider),
      isA<ProvidersCatalogRepository>(),
    );
    expect(
      container.read(incidentsRepositoryProvider),
      isA<SupabaseIncidentsRepository>(),
    );
    expect(
      container.read(amenitiesRepositoryProvider),
      isA<SupabaseAmenitiesRepository>(),
    );
    expect(
      container.read(authRepositoryProvider),
      isA<SupabaseAuthRepository>(),
    );
    expect(
      container.read(sessionRepositoryProvider),
      isA<SupabaseSessionRepository>(),
    );
    expect(
      container.read(profileRepositoryProvider),
      isA<SupabaseProfileRepository>(),
    );
  });

  group('ImagePickerPhotoPicker', () {
    late _FakeImagePicker fake;

    setUp(() {
      fake = _FakeImagePicker();
      ImagePickerPlatform.instance = fake;
    });

    test('the camera returns one photo at reduced quality', () async {
      final photos = await ImagePickerPhotoPicker().pick(PhotoSource.camera);

      expect(photos.single.path, 'shot.jpg');
      expect(fake.lastSource, ImageSource.camera);
      expect(fake.lastQuality, 70);
    });

    test('the gallery returns several photos', () async {
      final photos = await ImagePickerPhotoPicker().pick(PhotoSource.gallery);

      expect(photos.map((p) => p.path), ['a.jpg', 'b.jpg']);
      expect(fake.lastQuality, 70);
    });

    test('the default provider uses the real picker implementation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(photoPickerProvider),
        isA<ImagePickerPhotoPicker>(),
      );
    });
  });

  group('Env', () {
    test('loopback hosts map to the Android emulator alias', () {
      expect(
        Env.androidEmulatorUrl('http://127.0.0.1:64321'),
        'http://10.0.2.2:64321',
      );
      expect(
        Env.androidEmulatorUrl('http://localhost:54321'),
        'http://10.0.2.2:54321',
      );
      expect(
        Env.androidEmulatorUrl('https://abc.supabase.co'),
        'https://abc.supabase.co',
      );
    });

    test('settings come from the loaded .env', () {
      dotenv.loadFromString(
        envString:
            'SUPABASE_URL=https://abc.supabase.co\n'
            'SUPABASE_PUBLISHABLE_KEY=pk\n',
      );
      expect(Env.supabaseUrl, 'https://abc.supabase.co');
      expect(Env.supabasePublishableKey, 'pk');
      expect(Env.publicAppUrl, 'https://vecinoo.app/');
    });
  });
}
