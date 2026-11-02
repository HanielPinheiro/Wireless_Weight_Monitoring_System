
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:precious_weight/models/enums.dart';

List<LogModel> logsFromJson(String str) {
  final List<dynamic> jsonArray = json.decode(str);
  return jsonArray.map((item) {
    return LogModel.fromApiArray(item as List<dynamic>);
  }).toList();
}

// Keep the rest the same
LogModel logFromJson(String str) => LogModel.fromJson(json.decode(str));
String logToJson(LogModel data) => json.encode(data.toJson());
String logsToJson(List<LogModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class LogModel {
  final dynamic entity;
  final int revision;
  final String revisionType;
  final DateTime revisionDate;
  final String? username;

  LogModel({
    required this.entity,
    required this.revision,
    required this.revisionType,
    required this.revisionDate,
    this.username,
  });

  // Factory constructor for your specific API response
  factory LogModel.fromApiArray(List<dynamic> array) {
    final entity = array[0] as Map<String, dynamic>;
    final revisionInfo = array[1] as Map<String, dynamic>;
    final action = array[2] as String;

    return LogModel(
      entity: entity,
      revision: revisionInfo['id'],
      revisionType: action, // Already in string format
      revisionDate: DateTime.parse(revisionInfo['revisionDate']),
      username: revisionInfo['username'],
    );
  }


  // For regular JSON if needed
  factory LogModel.fromJson(Map<String, dynamic> json) => LogModel(
    entity: json['entity'],
    revision: json['revision'],
    revisionType: json['revisionType'],
    revisionDate: DateTime.parse(json['revisionDate']),
    username: json['username'],
  );

  Map<String, dynamic> toJson() => {
    'entity': entity,
    'revision': revision,
    'revisionType': revisionType,
    'revisionDate': revisionDate.toIso8601String(),
    'username': username,
  };

  String getActionText() {
    switch (revisionType) {
      case 'ADD':
        return 'Criar';
      case 'MOD':
        return 'Atualizar';
      case 'DEL':
        return 'Deletar';
      default:
        return revisionType;
    }
  }

  static IconData getLogIcon(LogType logType) {
    switch (logType) {
      case LogType.baby:
        return Icons.child_care;
      case LogType.scale:
        return Icons.scale;
      case LogType.weight:
        return Icons.fitness_center;
    }
  }

  static String getNameFrom(LogType logType) {
    switch (logType) {
      case LogType.baby:
        return "Bebês";
      case LogType.scale:
        return "Balanças";
      case LogType.weight:
        return "Pesos";
    }
  }
}