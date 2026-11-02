import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:io';
import 'package:http/io_client.dart';

import '../../api/user_api.dart';
import '../helper/api_error_handler.dart';
import '../helper/constants.dart';

class ApiService {
  static Future<String> apiConn(String url, {String? body, Map<String, String>? header, int? timeout}) async {
    late final http.Client client;

    /*-- start debug code (when use pixel 6 emulator with an api address that has ssh implemented --*/
    if (kDebugMode) {
      final ioClient = HttpClient()..badCertificateCallback = (X509Certificate cert, String host, int port) {
          return host == 'COLOCAR_IP_AQUI';// Trust the connection explicitly if it matches your VPS IP
        };
      client = IOClient(ioClient);
    } else {
      client = http.Client(); // Standard secure client for production
    }
    /*-- end debug code --*/

    timeout = timeout ?? 2;

    try {
      final uri = Uri.parse(url);
      final response = await client.post(uri, body: body, headers: header ?? {})
          //     .timeout(Duration(seconds: timeout), onTimeout: () {
          //   throw TimeoutException('The request timed out after ${timeout} seconds.');
          // })
          ;

      final responseBody = Utf8Decoder().convert(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        try {
          final errorJson = jsonDecode(responseBody);
          throw ApiException(statusCode: response.statusCode, message: errorJson['message'] ?? 'Request failed', details: errorJson['errors'] ?? responseBody);
        } catch (_) {
          throw ApiException(statusCode: response.statusCode, message: 'Request failed with status ${response.statusCode}', details: responseBody);
        }
      }
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, message: 'Network error: ${e.message}', details: e.toString());
    } on TimeoutException catch (e) {
      throw ApiException(statusCode: 0, message: 'Timeout error: ${e.message}', details: e.toString());
    } finally {
      client.close();
    }
  }

  static Future<Uint8List?> getQrCode(String url) async {
    int timeout = 2;
    final client = http.Client();
    try {
      final response = await client.post(Uri.parse(url), headers: {'Authorization': 'Bearer ${UserApi().token!.accessToken}'})
          //     .timeout(Duration(seconds: timeout), onTimeout: () {
          //   throw TimeoutException('The request timed out after ${timeout} seconds.');
          // })
          ;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        throw ApiException(statusCode: response.statusCode, message: 'Image download failed with status ${response.statusCode}', details: response.body);
      }
    } on http.ClientException catch (e) {
      throw ApiException(statusCode: 0, message: 'Network error: ${e.message}', details: e.toString());
    } finally {
      client.close();
    }
  }

  static Future<bool> uploadQrCode(String babyCode, Uint8List? image) async {
    final request = http.MultipartRequest('POST', Uri.parse("${address_api}${api_baby_updateQr.replaceAll(api_pattern_code, babyCode)}"));
    request.files.add(http.MultipartFile.fromBytes('file', (image != null) ? image : [], filename: '${babyCode}_qr.png', contentType: MediaType('image', 'png')));
    request.headers['Authorization'] = 'Bearer ${UserApi().token!.accessToken}';

    int timeout = 2;
    final response = await request.send()
        //     .timeout(Duration(seconds: timeout), onTimeout: () {
        //   throw TimeoutException('The request timed out after ${timeout} seconds.');
        // })
        ;
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw ApiException(statusCode: response.statusCode, message: 'Upload failed', details: responseBody);
    }
    return true;
  }
}

class SafeApi {
  static Future<T> call<T>({required BuildContext context, required Future<T> Function() apiCall, Future<void> Function()? onSuccess, bool abortErrorMessage = false}) async {
    try {
      final T result = await apiCall();
      if (onSuccess != null) await onSuccess();
      return result;
    } catch (error) {
      if(!abortErrorMessage) await ApiErrorHandler.handleError(context, error);
      throw error;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({required this.statusCode, required this.message, this.details});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
