import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../api/baby_api.dart';
import '../../models/scales.dart';
import '../../api/scale_api.dart';
import '../services/api_service.dart';

class ScalesProvider with ChangeNotifier {
  final _scaleApi = new ScaleApi();
  final _babyApi = new BabyApi();

  List<ScaleModel> _scales = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<ScaleModel> get scales => _scales;

  ScalesProvider() {
    loadScales();
  }

  Future<void> _updateCache() async {
    try {
      _isLoading = true;
      notifyListeners();

      _scales = (await _scaleApi.listScales())!;
      _scales.forEach((p) async {
        await _populatesScaleModelWithExtraData(p);
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _populatesScaleModelWithExtraData(ScaleModel newScale) async {
    try {
      final data = await _scaleApi.getScaleDataFromHash(newScale.hash);
      newScale.mac = data[0];
      newScale.pop = data[1];
      if (newScale.babyId != null) newScale.assignedBaby = await _babyApi.searchBaby(newScale.babyId!.toString());
    } finally {}
  }

  int _getIndexFromList(int scale_id) {
    return _scales.indexWhere((b) => b.id == scale_id);
  }

  ScaleModel? _scaleInCache(int scale_id) {
    final index = _scales.indexWhere((b) => b.id == scale_id);
    return (index != -1) ? _scales[index] : null;
  }

  Future<void> _setNewScaleToCache(ScaleModel scale) async {
    await _populatesScaleModelWithExtraData(scale);
    _scales.add(scale);
  }

  Future<void> loadScales() async {
    await _updateCache();
  }

  Future<ScaleModel> getScaleById(BuildContext context, int scale_id) async {
    try {
      ScaleModel? scale = null;

      scale = _scaleInCache(scale_id);
      if (scale == null) {
        await SafeApi.call(
            context: context,
            apiCall: () async {
              await _updateCache();
            });
        scale = _scaleInCache(scale_id);
        if (scale == null) throw new Exception("Scale not found");
      }

      return scale;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<ScaleModel?> setNewScale(BuildContext context, String hash) async {
    try {
      final scale = await SafeApi.call<ScaleModel?>(
          context: context,
          apiCall: () async {
            return await _scaleApi.setNewScale(hash);
          });
      if (scale == null) throw new Exception("Can't add new scale");
      await _setNewScaleToCache(scale);
      return scale;
    } catch (e) {
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> setOrUnsetBaby(BuildContext context, int scale_id, {String? baby_code}) async {
    try {
      await SafeApi.call(
          context: context,
          apiCall: () async {
            await _scaleApi.setOrUnsetBaby(scale_id.toString(), baby_code: baby_code);
          });
      final updatedScale = await getScaleById(context, scale_id);
      final index = _getIndexFromList(scale_id);
      if (updatedScale.babyId != null && index != -1) {
        final s = new ScaleModel(
          babyId: null,
          assignedBaby: null,
          id: updatedScale.id,
          hash: updatedScale.hash,
          status: updatedScale.status,
          pop: updatedScale.pop,
          mac: updatedScale.mac,
          isConnected: updatedScale.isConnected,
        );
        _scales[index] = s;
      } else {
        final baby_id = int.parse(baby_code!);
        final bb = await _babyApi.searchBaby(baby_code);
        final s = new ScaleModel(
          babyId: baby_id,
          assignedBaby: bb,
          id: updatedScale.id,
          hash: updatedScale.hash,
          status: updatedScale.status,
          pop: updatedScale.pop,
          mac: updatedScale.mac,
          isConnected: updatedScale.isConnected,
        );
        _scales[index] = s;
      }
    } catch (e) {
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> enableOrDisableScale(BuildContext context, ScaleModel scale) async {
    try {
      final isActive = scale.status == 1;
      await SafeApi.call(
        context: context,
        apiCall: () async {
          await _scaleApi.enableOrDisableScale(scale.id.toString(), !isActive);
        },
      );
      final idx = _getIndexFromList(scale.id);
      if (idx != -1) _scales[idx] = scale.copyWith(status: !isActive ? 1 : 0);
    } catch (e) {
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<List<String>> getScaleDataFromHash(BuildContext context, String hash) async {
    try {
      return await SafeApi.call<List<String>>(
          context: context,
          apiCall: () async {
            return await _scaleApi.getScaleDataFromHash(hash);
          });
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<Uint8List?> getScaleQrFromHash(BuildContext context, String hash) async {
    try {
      return await SafeApi.call<Uint8List?>(
        context: context,
        apiCall: () async {
          return await _scaleApi.getScaleQrFromHash(hash);
        },
      );
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<int?> getScaleIdFromHash(BuildContext context, String hash) async {
    try {
      return await SafeApi.call<int?>(
          context: context,
          apiCall: () async {
            return await _scaleApi.getIdByHash(hash);
          });
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<String> requestWeightNow(BuildContext context, int scale_id) async {
    try {
      return await SafeApi.call<String>(
        context: context,
        apiCall: () async {
          final answer = await _scaleApi.requestWeightNow(scale_id.toString());
          final result = answer.split(":");
          final r = result[result.length-1];
          return r.substring(0, r.length-1);
        },
      );
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<String> requestChangeWifi(BuildContext context, int scale_id) async {
    try {
      return await SafeApi.call<String>(
        context: context,
        apiCall: () async {
          final result = await _scaleApi.requestChangeWifi(scale_id.toString());
          return result == "true" ? "Wi-Fi resetado com sucesso" : "Erro ao tentar resetar Wi-Fi";
        },
      );
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<String> requestTare(BuildContext context, int scale_id) async {
    try {
      return await SafeApi.call<String>(
        context: context,
        apiCall: () async {
          final result = await _scaleApi.requestTare(scale_id.toString());
          return result == "true" ? "Tara realizada com sucesso" : "Erro ao realizar tara";
        },
      );
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<String> requestWifiStrength(BuildContext context, int scale_id) async {
    try {
      ScaleModel? scale = _scaleInCache(scale_id);

      if (scale == null) {
        await SafeApi.call(
            context: context,
            apiCall: () async {
              await _updateCache();
            });
        scale = _scaleInCache(scale_id);
        if (scale == null) throw new Exception("Scale not found");
      } else {
        await SafeApi.call(
            context: context,
            abortErrorMessage: true,
            apiCall: () async {
              try {
                final d = await _scaleApi.getWifiStrength(scale_id.toString());
                final result = d.split(":");
                final value = result[result.length - 1];
                scale!.wifiStrength = int.tryParse(value.substring(0, value.length - 1)) ?? 0;
              } catch (e) {
                throw e;
              }
            });
      }
      return scale.wifiStrength.toString();
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  void updateScaleConnectivity(int scale_id, bool state) {
    try {
      int idx = _getIndexFromList(scale_id);
      if (idx != -1)
        _scales[idx] = _scales[idx].copyWith(isConnected: state);
    }
    catch(e){
      throw e;
    } finally {
      notifyListeners();
    }
  }

}
