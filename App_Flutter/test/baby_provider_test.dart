import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:precious_weight/api/baby_api.dart';
import 'package:precious_weight/api/scale_api.dart';
import 'package:precious_weight/models/baby.dart';
import 'package:precious_weight/models/scales.dart';
import 'package:precious_weight/models/weight.dart';
import 'package:precious_weight/repository/providers/baby_provider.dart';
import 'package:precious_weight/views/babies/babies.dart';
import 'package:precious_weight/views/scales/scales_babies.dart';

class FakeBabyApi extends BabyApi {
  FakeBabyApi({
    this.listBabiesHandler,
    this.searchBabyHandler,
    this.insertBabyHandler,
    this.getQrCodeHandler,
    this.updateBabyHandler,
    this.enableOrDisableBabyHandler,
    this.updateBabyQrHandler,
  });

  Future<List<BabyModel>?> Function()? listBabiesHandler;
  Future<BabyModel?> Function(String babyCode)? searchBabyHandler;
  Future<BabyModel?> Function(String babyLikeJson)? insertBabyHandler;
  Future<Uint8List?> Function(String babyCode)? getQrCodeHandler;
  Future<BabyModel> Function(String babyCode, Map<String, dynamic> babyLikeJson)? updateBabyHandler;
  Future<bool> Function(String babyCode, bool enable)? enableOrDisableBabyHandler;
  Future<bool> Function(String babyCode, Uint8List? image)? updateBabyQrHandler;

  @override
  Future<List<BabyModel>?> listBabies() async => await listBabiesHandler?.call();

  @override
  Future<BabyModel?> searchBaby(String baby_code) async => await searchBabyHandler?.call(baby_code);

  @override
  Future<BabyModel?> insertBaby(String babyLikeJson) async => await insertBabyHandler!.call(babyLikeJson);

  @override
  Future<Uint8List?> getQrCode(String baby_code) async => await getQrCodeHandler?.call(baby_code);

  @override
  Future<BabyModel> updateBaby(String baby_code, Map<String, dynamic> babyLikeJson) async => await updateBabyHandler!.call(baby_code, babyLikeJson);

  @override
  Future<bool> enableOrDisableBaby(String baby_code, [bool enable = true]) async => await enableOrDisableBabyHandler!.call(baby_code, enable);

  @override
  Future<bool> updateBabyQr(String baby_code, Uint8List? image) async => await updateBabyQrHandler!.call(baby_code, image);
}

class FakeScaleApi extends ScaleApi {
  FakeScaleApi({
    this.getScaleFromIdHandler,
  });

  Future<ScaleModel?> Function(String idLikeString)? getScaleFromIdHandler;

  @override
  Future<ScaleModel?> getScaleFromId(String idLikeString) async => await getScaleFromIdHandler?.call(idLikeString);
}

class TestBabyModel extends BabyModel {
  TestBabyModel({
    required super.hospitalRegister,
    super.id,
    super.name,
    super.motherName,
    super.birthDate,
    super.isActive,
    super.qrCodeImage,
    super.qrCodeText,
    super.assignedScale,
    super.weightHour,
    super.hasQrCode,
    super.scaleId,
    this.weights = const [],
  });

  final List<WeightModel> weights;

  @override
  Future<List<WeightModel>?> getWeights() async => weights;
}

Future<BuildContext> _pumpContextHost(
  WidgetTester tester, {
  required BabyProvider provider,
}) async {
  BuildContext? capturedContext;

  await tester.pumpWidget(
    ChangeNotifierProvider<BabyProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pump();

  return capturedContext!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BabyProvider', () {
    testWidgets('loads babies, enriches extra data, and exposes filtered lists', (tester) async {
      final fakeBabyApi = FakeBabyApi(
        listBabiesHandler: () async => [
          TestBabyModel(
            id: 2,
            hospitalRegister: 'HR-2',
            name: 'Alice',
            motherName: 'Maria',
            birthDate: DateTime(2024, 1, 10),
            isActive: true,
            weightHour: '08:00',
            hasQrCode: true,
            scaleId: 9,
          ),
          TestBabyModel(
            id: 1,
            hospitalRegister: 'HR-1',
            name: 'Bruno',
            motherName: 'Carla',
            birthDate: DateTime(2024, 1, 11),
            isActive: false,
            weightHour: '09:00',
          ),
        ],
        getQrCodeHandler: (_) async => Uint8List.fromList(const [1, 2, 3]),
      );
      final fakeScaleApi = FakeScaleApi(
        getScaleFromIdHandler: (_) async => ScaleModel(id: 9, hash: 'hash-9', status: 1, babyId: 2),
      );
      final provider = BabyProvider(babyApi: fakeBabyApi, scaleApi: fakeScaleApi, autoload: false);

      await provider.loadBabies();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(provider.babies.map((baby) => baby.id), [1, 2]);
      expect(provider.activeBabies.length, 1);
      expect(provider.inactiveBabies.length, 1);
      expect(provider.availableBabies, isEmpty);
      expect(provider.babies.last.assignedScale?.id, 9);
      expect(provider.babies.last.qrCodeImage, isNotNull);
    });

    testWidgets('validates and caches newly added babies', (tester) async {
      String? insertedPayload;
      final fakeBabyApi = FakeBabyApi(
        insertBabyHandler: (payload) async {
          insertedPayload = payload;
          return TestBabyModel(
            id: 10,
            hospitalRegister: 'HR-10',
            name: 'Nina',
            motherName: 'Laura',
            birthDate: DateTime(2024, 3, 1),
            isActive: true,
            weightHour: '10:00',
          );
        },
      );
      final provider = BabyProvider(babyApi: fakeBabyApi, scaleApi: FakeScaleApi(), autoload: false);
      final context = await _pumpContextHost(tester, provider: provider);

      final added = await provider.addBaby(
        context,
        TestBabyModel(
          hospitalRegister: 'HR-10',
          name: 'Nina',
          motherName: 'Laura',
          birthDate: DateTime(2024, 3, 1),
          isActive: true,
          weightHour: '10:00',
        ),
      );
      await tester.pump();

      expect(insertedPayload, contains('"babyName":"Nina"'));
      expect(added.id, 10);
      expect(provider.babies.single.id, 10);
    });

    testWidgets('rejects invalid baby payloads before calling the API', (tester) async {
      final fakeBabyApi = FakeBabyApi(
        insertBabyHandler: (_) async => throw Exception('API should not be called'),
      );
      final provider = BabyProvider(babyApi: fakeBabyApi, scaleApi: FakeScaleApi(), autoload: false);
      final context = await _pumpContextHost(tester, provider: provider);

      await expectLater(
        provider.addBaby(
          context,
          TestBabyModel(
            hospitalRegister: '',
            name: 'Nope',
            motherName: 'Mother',
            birthDate: DateTime(2024, 1, 1),
            isActive: true,
            weightHour: '08:00',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('updates activation state in cache using the shared API flow', (tester) async {
      final fakeBabyApi = FakeBabyApi(
        listBabiesHandler: () async => [
          TestBabyModel(
            id: 7,
            hospitalRegister: 'HR-7',
            name: 'Lia',
            motherName: 'Paula',
            birthDate: DateTime(2024, 2, 1),
            isActive: true,
            weightHour: '12:00',
          ),
        ],
        enableOrDisableBabyHandler: (_, __) async => true,
      );
      final provider = BabyProvider(babyApi: fakeBabyApi, scaleApi: FakeScaleApi(), autoload: false);
      final context = await _pumpContextHost(tester, provider: provider);

      await provider.loadBabies();
      await provider.enableOrDisableBaby(context, provider.babies.single, enable: false);

      expect(provider.babies.single.isActive, isFalse);
    });
  });

  group('Baby screens', () {
    testWidgets('ScaleBabies loads and renders available babies from BabyProvider', (tester) async {
      final provider = BabyProvider(
        babyApi: FakeBabyApi(
          listBabiesHandler: () async => [
            TestBabyModel(
              id: 1,
              hospitalRegister: 'HR-1',
              name: 'Helena',
              motherName: 'Ana',
              birthDate: DateTime(2024, 4, 10),
              isActive: true,
              weightHour: '08:00',
            ),
            TestBabyModel(
              id: 2,
              hospitalRegister: 'HR-2',
              name: 'Inativo',
              motherName: 'Bea',
              birthDate: DateTime(2024, 4, 11),
              isActive: false,
              weightHour: '09:00',
            ),
          ],
        ),
        scaleApi: FakeScaleApi(),
        autoload: false,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<BabyProvider>.value(
          value: provider,
          child: MaterialApp(
            home: ScaleBabies(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Helena'), findsOneWidget);
      expect(find.textContaining('Inativo'), findsNothing);
    });

    testWidgets('BabiesPage loads and renders active babies', (tester) async {
      final provider = BabyProvider(
        babyApi: FakeBabyApi(
          listBabiesHandler: () async => [
            TestBabyModel(
              id: 3,
              hospitalRegister: 'HR-3',
              name: 'Sofia',
              motherName: 'Clara',
              birthDate: DateTime(2024, 5, 1),
              isActive: true,
              weightHour: '07:00',
            ),
          ],
        ),
        scaleApi: FakeScaleApi(),
        autoload: false,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<BabyProvider>.value(
          value: provider,
          child: MaterialApp(
            home: BabiesPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Sofia'), findsOneWidget);
      expect(find.textContaining('Último peso:'), findsOneWidget);
    });
  });
}
