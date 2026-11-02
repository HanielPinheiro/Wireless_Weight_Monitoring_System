import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../api/baby_api.dart';
import '../../api/scale_api.dart';
import '../../models/baby.dart';
import '../services/api_service.dart';

class BabyProvider with ChangeNotifier {
  final ScaleApi _scaleApi;
  final BabyApi _babyApi;

  final Map<int, BabyModel> _babiesMap = {};

  List<BabyModel> get babies => _babiesMap.values.toList()..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
  List<BabyModel> get activeBabies => babies.where((baby) => baby.isActive == true).toList();
  List<BabyModel> get inactiveBabies => babies.where((baby) => baby.isActive != true).toList();
  List<BabyModel> get availableBabies => activeBabies.where((baby) => baby.scaleId == null).toList();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  BabyProvider({BabyApi? babyApi, ScaleApi? scaleApi, bool autoload = true})
      : _babyApi = babyApi ?? BabyApi(),
        _scaleApi = scaleApi ?? ScaleApi() {
    if (autoload) {
      loadBabies();
    }
  }

  Future<void> _updateCache() async {
    try {
      _isLoading = true;
      notifyListeners();

      final bb = await _babyApi.listBabies() ?? [];
      _babiesMap.clear();
      for (final newBaby in bb) {
        if (newBaby.id == null) continue;
        _babiesMap[newBaby.id!] = newBaby;
        unawaited(_populateBabyModelWithExtraData(newBaby));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _populateBabyModelWithExtraData(BabyModel newBaby) async {
    final babyId = newBaby.id;
    if (babyId == null) return;

    try {
      BabyModel tempBaby = newBaby;

      if (newBaby.hasQrCode) {
        final qrData = await _babyApi.getQrCode(babyId.toString());
        if (qrData != null) {
          tempBaby = tempBaby.copyWith(qrCodeImage: Image.memory(qrData), hasQr: true);
        }
      }

      if (newBaby.scaleId != null) {
        final scale = await _scaleApi.getScaleFromId(newBaby.scaleId!.toString());
        tempBaby = tempBaby.copyWith(assignedScale: scale);
      }

      _babiesMap[babyId] = tempBaby;
    } catch (_) {
      _babiesMap[babyId] = newBaby;
    } finally {
      notifyListeners();
    }
  }

  bool _babyExists(int baby_id) => _babiesMap.containsKey(baby_id);

  BabyModel? _getBabyFromMap(int baby_id) => _babiesMap[baby_id];

  void _validateBaby(BabyModel baby, {bool requireId = false}) {
    if (requireId && baby.id == null) {
      throw ArgumentError('Baby id is required');
    }
    if (baby.hospitalRegister.trim().isEmpty) {
      throw ArgumentError('Hospital register is required');
    }
    if ((baby.name ?? '').trim().isEmpty) {
      throw ArgumentError('Baby name is required');
    }
    if ((baby.motherName ?? '').trim().isEmpty) {
      throw ArgumentError('Mother name is required');
    }
    if (baby.birthDate == null) {
      throw ArgumentError('Birth date is required');
    }
    if (baby.isActive == null) {
      throw ArgumentError('Baby active status is required');
    }
    if ((baby.weightHour ?? '').trim().isEmpty) {
      throw ArgumentError('Weight schedule is required');
    }
  }

  Future<void> _setNewBabyToCache(BabyModel baby) async {
    final babyId = baby.id;
    if (babyId == null) {
      throw Exception('Baby id is required');
    }
    _babiesMap[babyId] = baby;
    await _populateBabyModelWithExtraData(baby);
  }

  Future<void> loadBabies() async {
    await _updateCache();
  }

  Future<BabyModel> getBabyById(BuildContext context, int id) async {
    try {
      BabyModel? baby = _babyExists(id) ? _getBabyFromMap(id) : null;
      if (baby == null) {
        await SafeApi.call(context: context, apiCall: () async => await _updateCache());
        baby = _babyExists(id) ? _getBabyFromMap(id) : null;
        if (baby == null) throw new Exception("Baby not found");
      }
      return baby;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleBabyStatus(BuildContext context, BabyModel baby) async {
    await enableOrDisableBaby(context, baby);
  }

  Future<void> enableOrDisableBaby(BuildContext context, BabyModel baby, {bool? enable}) async {
    try {
      final babyId = baby.id;
      if (babyId == null) throw Exception("Baby id is required");

      final nextState = enable ?? !(baby.isActive ?? false);
      final result = await SafeApi.call<bool>(context: context, apiCall: () async => await _babyApi.enableOrDisableBaby(babyId.toString(), nextState));
      if (!result) throw Exception("Erro ao alterar estado");
      if (_babyExists(babyId)) _babiesMap[babyId] = baby.copyWith(isActive: nextState);
    } catch (e) {
      return;
    } finally {
      notifyListeners();
    }
  }

  Future<BabyModel> addBaby(BuildContext context, BabyModel newBaby) async {
    try {
      _validateBaby(newBaby);
      final baby = await SafeApi.call<BabyModel?>(context: context, apiCall: () async => await _babyApi.insertBaby(babyToJson(newBaby)));
      if (baby == null) throw Exception("Falha ao adicionar novo bebê");
      await _setNewBabyToCache(baby);
      return baby;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<BabyModel> updateBaby(BuildContext context, BabyModel updatedBaby) async {
    try {
      _validateBaby(updatedBaby, requireId: true);
      final baby = await SafeApi.call<BabyModel?>(context: context, apiCall: () async => await _babyApi.updateBaby(updatedBaby.id.toString(), updatedBaby.toJson()));
      if (baby == null) throw Exception("Falha ao adicionar novo bebê");
      await _setNewBabyToCache(baby);
      return baby;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateQrCode(BuildContext context, int baby_id, Uint8List? qrImage) async {
    try {
      final baby = _getBabyFromMap(baby_id);
      if (baby == null) throw new Exception("Bebe não localizado!");
      final res = await SafeApi.call<bool>(context: context, apiCall: () async => await _babyApi.updateBabyQr(baby_id.toString(), qrImage));
      if (!res) throw Exception("Falha ao atualizar qr code!");
      _babiesMap[baby_id] = baby.copyWith(
        hasQr: qrImage != null,
        qrCodeImage: qrImage != null ? Image.memory(qrImage) : null,
      );
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }
}
