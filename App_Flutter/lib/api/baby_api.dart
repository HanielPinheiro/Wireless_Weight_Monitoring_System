import 'dart:convert';
import 'dart:typed_data';

import '../models/baby.dart';
import '../repository/helper/constants.dart';
import '../repository/services/api_service.dart';
import 'user_api.dart';

class BabyApi {
  Future<List<BabyModel>?> listBabies() async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      return babiesFromJson(await ApiService.apiConn("${address_api}${api_baby_list}", header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<BabyModel?> searchBaby(String baby_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      final result = await ApiService.apiConn("${address_api}${api_baby_search.replaceAll(api_pattern_code, baby_code)}", header: _header);
      return babyFromJson(result);
    } catch (error) {
      throw error;
    }
  }

  Future<BabyModel?> insertBaby(String babyLikeJson) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      return babyFromJson(await ApiService.apiConn("${address_api}${api_baby_new}", body: babyLikeJson, header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<Uint8List?> getQrCode(String baby_code) async {
    try {
      return await ApiService.getQrCode("${address_api}${api_baby_getQr.replaceAll(api_pattern_code, baby_code)}");
    } catch (error) {
      throw error;
    }
  }

  Future<bool> updateBabyQr(String baby_code, Uint8List? image) async {
    try {
      await ApiService.uploadQrCode(baby_code, image);
      return true;
    } catch (error) {
      throw error;
    }
  }

  Future<BabyModel> updateBaby(String baby_code, Map<String, dynamic> babyLikeJson) async {
    try {
      final _body = jsonEncode(babyLikeJson);
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      return  babyFromJson(await ApiService.apiConn("${address_api}${api_baby_update.replaceAll(api_pattern_code, baby_code)}", body: _body, header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<bool> enableOrDisableBaby(String baby_code, [bool enable = true]) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      if(enable) await ApiService.apiConn("${address_api}${api_baby_enable.replaceAll(api_pattern_code, baby_code)}", header: _header);
      else await ApiService.apiConn("${address_api}${api_baby_disable.replaceAll(api_pattern_code, baby_code)}", header: _header);
      return true;
    } catch (error) {
      throw error;
    }
  }
}
