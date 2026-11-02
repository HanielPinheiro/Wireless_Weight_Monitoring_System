import 'dart:convert';
import 'dart:typed_data';

import '../models/scales.dart';
import '../repository/helper/constants.dart';
import '../repository/services/api_service.dart';
import 'user_api.dart';

class ScaleApi {
  Future<List<ScaleModel>?> listScales() async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      return scalesFromJson(await ApiService.apiConn("${address_api}${api_scale_list}", header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<ScaleModel?> getScaleFromId(String idLikeString) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      return scaleFromJson(await ApiService.apiConn("${address_api}${api_scale_search.replaceAll(api_pattern_code, idLikeString)}", header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<ScaleModel?> setNewScale(String hash) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      return scaleFromJson(await ApiService.apiConn("${address_api}${api_scale_set.replaceAll(api_pattern_hash, hash)}", header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<bool> enableOrDisableScale(String scale_code, [bool enable = true]) async {
    final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
    try {
      if (enable)
        await ApiService.apiConn("${address_api}${api_scale_enable.replaceAll(api_pattern_code, scale_code)}", header: _header);
      else
        await ApiService.apiConn("${address_api}${api_scale_disable.replaceAll(api_pattern_code, scale_code)}", header: _header);
      return true;
    } catch (error) {
      throw error;
    }
  }

  Future<bool> setOrUnsetBaby(String scale_code, {String? baby_code}) async {
    try {
      String _body;
      String _uri;
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};

      if (baby_code == null) {
        _body = jsonEncode({"scaleId": scale_code});
        _uri = "${address_api}${api_scale_unsetBaby}";
      } else {
        _body = jsonEncode({"scaleId": scale_code, "babyId": baby_code});
        _uri = "${address_api}${api_scale_setBaby}";
      }

      await ApiService.apiConn(_uri, body: _body, header: _header);
      return true;
    } catch (error) {
      throw error;
    }
  }

  Future<int?> getIdByHash(String hash) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      final result = await ApiService.apiConn("${address_api}${api_scale_id_by_hash.replaceAll(api_pattern_hash, hash)}", header: _header);
      if (result.isEmpty) return null;
      return scaleFromJson(result).id;
    } catch (error) {
      if(error is ApiException){
        if(error.statusCode ==  404) return null;
      }
      throw error;
    }
  }

  Future<List<String>> getScaleDataFromHash(String hash) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      final result = await ApiService.apiConn("${address_api}${api_scaleData_get.replaceAll(api_pattern_hash, hash)}", header: _header);
      final myJson = json.decode(result);
      return [myJson['mac'], myJson['pop']];
    } catch (error) {
      throw error;
    }
  }

  Future<Uint8List?> getScaleQrFromHash(String hash) async {
    try {
      return await ApiService.getQrCode("${address_api}${api_scaleData_getQr.replaceAll(api_pattern_hash, hash)}");
    } catch (error) {
      throw error;
    }
  }

  Future<String> requestWeightNow(String scale_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      return await ApiService.apiConn("${address_api}${api_scale_measure_now.replaceAll(api_pattern_code, scale_code)}", header: _header);
    } catch (error) {
      throw error;
    }
  }

  Future<String> requestTare(String scale_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      return await ApiService.apiConn("${address_api}${api_scale_tare.replaceAll(api_pattern_code, scale_code)}", header: _header);
    } catch (error) {
      throw error;
    }
  }

  Future<String> requestChangeWifi(String scale_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      return await ApiService.apiConn("${address_api}${api_scale_change_wifi.replaceAll(api_pattern_code, scale_code)}", header: _header);
    } catch (error) {
      throw error;
    }
  }

  Future<String> getWifiStrength(String scale_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      return await ApiService.apiConn("${address_api}${api_scale_wifi_strength.replaceAll(api_pattern_code, scale_code)}", header: _header);
    } catch (error) {
      throw error;
    }
  }
}
