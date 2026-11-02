import 'dart:convert';
import '../models/user.dart';
import '../repository/helper/constants.dart';
import '../repository/services/api_service.dart';

class UserApi {
  UserApi._internal(); // Private constructor
  static final UserApi _instance = UserApi._internal();
  factory UserApi() => _instance;

  User? _user;
  Token? get token => _user!.token;
  User? get user => _user;

  Future<void> Login(String username, String password) async {
    try {

      if(username == "") username = "teste@teste.com";
      if(password == "") password = "123";

      final _body = jsonEncode({
        'email': username,
        'password': password,
      });

      final _header = {'Content-Type': 'application/json'};

      _user = userFromJson(await ApiService.apiConn("${address_api}${api_user_login}", body: _body, header: _header));
    }
    catch (error) {
      if (error is ApiException) {
        if(error.message.contains("Network error"))
          throw new Exception(error.details);
      }
      throw new Exception("Usuario ou senha incorretos!");
    }
  }
  Future<void> Logout() async {
    try {
      _user = null;
      // ApiConn("${address_api}${api_user_logout}");
    } catch (error) {
      throw error;
    }
  }

  Future<void> NewUser(String username, String password) async {
    print(username);
    try {
      final _body = jsonEncode({
        'email': username,
        'password': password,
        'organization': "Hospital Geral"
      });

      final _header = {'Content-Type': 'application/json'};
      await ApiService.apiConn("${address_api}${api_user_new}", body: _body, header: _header);
    } catch (error) {
      throw error;
    }
  }

  Future<void> ResetPassword(String username, String newPassword) async {
    try {
      final _body = jsonEncode({
        'email': username,
        'password': newPassword,
      });

      final _header = {'Content-Type': 'application/json'};

      await ApiService.apiConn("${address_api}${api_user_reset}", body: _body, header: _header);
    } catch (error) {
      throw error;
    }
  }

  Future<List<User>?> listUsers() async {
    try {
      final result = await ApiService.apiConn("${address_api}${api_user_list}");
      return usersFromJson(result);
    } catch (error) {
      throw error;
    }
  }


}
