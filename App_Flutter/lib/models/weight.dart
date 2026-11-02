import 'dart:convert';

import '../repository/helper/conversions.dart';
import 'baby.dart';
import 'scales.dart';

const String weight_id = 'weightId';
const String weight_date = 'weightDate';
const String weight_value = 'weightValue';

WeightModel weightFromJson(String str) => WeightModel.fromJson(json.decode(str));
List<WeightModel> weightsFromJson(String str) => List<WeightModel>.from(json.decode(str).map((x) => WeightModel.fromJson(x)));

String weightToJson(WeightModel data) => json.encode(data.toJson());
String weightsToJson(List<WeightModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));


class WeightModel {
  final int id;
  final DateTime date;
  final int scaleId;
  final int babyId;
  final double weight;

  WeightModel({
    required this.id,
    required this.date,
    required this.scaleId,
    required this.babyId,
    required this.weight,
  });

  static WeightModel fromJson(Map<String, dynamic> json) => WeightModel(
    id: json[weight_id],
    date: parseUtcTime(json[weight_date]),
    scaleId: json[scales_id],
    babyId: json[patient_id],
    weight: json[weight_value]
  );

  Map<String, dynamic> toJson() => {
    weight_id: id,
    weight_date: date.toIso8601String(), // Correct key for date
    scales_id: scaleId, // Fixed constant for scaleId
    patient_id: babyId, // Fixed constant for patientId
    weight_value: weight, // Fixed constant for weight
  };

  WeightModel copyWith({
    int? id,
    DateTime? date,
    int? scaleId,
    int? patientId,
    double? weight,
  }) => WeightModel(
    id: id ?? this.id,
    date: date ?? this.date,
    scaleId: scaleId ?? this.scaleId,
    babyId: patientId ?? this.babyId,
    weight: weight ?? this.weight,
  );
}