import '../models/logs.dart';
import '../repository/helper/constants.dart';
import '../repository/services/api_service.dart';
import 'user_api.dart';

class LogsApi {
  Future<List<LogModel>?> listBabies(String baby_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      final uri = "${address_api}${api_audit_babies.replaceAll(api_pattern_code, baby_code)}";
      final result = await ApiService.apiConn(uri, header: _header);
      return logsFromJson(result);
    } catch (error) {
      throw error;
    }
  }

  Future<List<LogModel>?> listScales(String scale_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      final uri = "${address_api}${api_audit_scales.replaceAll(api_pattern_code, scale_code)}";
      final result = await ApiService.apiConn(uri, header: _header);
       return logsFromJson(result);
    } catch (error) {
      throw error;
    }
  }

  Future<List<LogModel>?> listWeights(String baby_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      final uri = "${address_api}${api_audit_weights.replaceAll(api_pattern_code, baby_code)}";
      final result = await ApiService.apiConn(uri, header: _header);
      return logsFromJson(result);
    } catch (error) {
      throw error;
    }
  }
}
