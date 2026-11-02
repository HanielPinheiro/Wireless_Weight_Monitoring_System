import 'package:flutter/material.dart';
import 'package:precious_weight/repository/services/api_service.dart';

import '../../api/user_api.dart';
import '../../views/login/login.dart';

class ApiErrorHandler {
  static Future<void> handleError(BuildContext context, dynamic error) async {
    var message = error.toString();
    if(error is ApiException)
      message = error.message + " -> " + error.details;

    if (message.contains("401")) {
      await _handleUnauthorized(context);
    } else {
      await _showGenericError(context, message);
    }
  }

  static Future<void> _handleUnauthorized(BuildContext context) async {
    await showDialog(context: context, builder: (context) => AlertDialog(title: Text("Login Expirado"), content: Text("Faça login novamente")));
    UserApi().Logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  static Future<void> _showGenericError(BuildContext context, String message) async {
    await showDialog(context: context, builder: (context) => AlertDialog(title: Text("Erro de requisição"), content: Text(message.replaceAll("Exception:", ""))));
  }
}
