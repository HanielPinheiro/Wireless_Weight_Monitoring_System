import 'dart:convert';
import 'package:flutter/material.dart';

import 'scales.dart';
import 'weight.dart';
import '../api/weight_api.dart';
import '../repository/helper/conversions.dart';

const String patient_id = "babyId";
const String patient_name = "babyName";
const String patient_motherName = "babyMotherName";
const String patient_birthDate = "babyBirthDate";
const String patient_isActive = "babyState";
const String patient_weightHour = "babyWeightTime";
const String patient_hospitalRegister = "babyHospitalId";
const String patient_qrCodeText = "babyImageText";
const String patient_qrCode = "babyImageQr";
const String patient_scale = "scaleId";

BabyModel babyFromJson(String str) => BabyModel.fromJson(json.decode(str));

List<BabyModel> babiesFromJson(String str) => List<BabyModel>.from(json.decode(str).map((x) => BabyModel.fromJson(x)));

String babyToJson(BabyModel data) => json.encode(data.toJson());

String babiesToJson(List<BabyModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BabyModel {
  static const Object _sentinel = Object();

  final String hospitalRegister;
  final int? id;
  final String? name;
  final String? motherName;
  final DateTime? birthDate;
  final bool? isActive;
  final Image? qrCodeImage;
  final String? qrCodeText;
  final int? scaleId;
  final ScaleModel? assignedScale;
  final String? weightHour;
  final bool hasQrCode;

  BabyModel({
    required this.hospitalRegister,
    this.id,
    this.name,
    this.motherName,
    this.birthDate,
    this.isActive,
    this.qrCodeImage,
    this.qrCodeText,
    this.assignedScale,
    this.weightHour,
    this.hasQrCode = false,
    this.scaleId,
  });

  factory BabyModel.fromJson(Map<String, dynamic> json) {
    return BabyModel(
      id: json[patient_id],
      hospitalRegister: json[patient_hospitalRegister],
      name: json[patient_name],
      motherName: json[patient_motherName],
      birthDate: dateFormatter_dbToObj.parse(json[patient_birthDate]),
      qrCodeText: json[patient_qrCodeText],
      isActive: json[patient_isActive] == 1,
      hasQrCode: json[patient_qrCodeText] == null,
      weightHour: json[patient_weightHour],
      scaleId: json[patient_scale],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) patient_id: id,
        patient_hospitalRegister: hospitalRegister,
        patient_name: name!,
        patient_motherName: motherName!,
        patient_birthDate: dateFormatter_dbToObj.format(birthDate!),
        patient_isActive: isActive! == true ? 1 : 0,
        patient_qrCodeText: qrCodeText,
        patient_weightHour: weightHour,
        patient_scale: scaleId,
      };

  Future<List<WeightModel>?> getWeights() async {
    final myId = id.toString();
    final api = new WeightApi();
    return await api.getBabyWeigths(myId);
  }

  BabyModel copyWith({
    String? hospitalRegister,
    int? id,
    String? name,
    String? motherName,
    DateTime? birthDate,
    bool? isActive,
    Object? qrCodeImage = _sentinel,
    Nullable<String?>? qrCodeText,
    Object? assignedScale = _sentinel,
    String? weightHour,
    bool? hasQr,
    Object? scaleId = _sentinel,
  }) {
    final hasQrImageUpdate = !identical(qrCodeImage, _sentinel);
    final hasAssignedScaleUpdate = !identical(assignedScale, _sentinel);
    final hasScaleIdUpdate = !identical(scaleId, _sentinel);

    final Image? resolvedQrImage;
    final String? resolvedQrText;

    if (qrCodeText != null) {
      resolvedQrText = qrCodeText.value;
      resolvedQrImage = null;
    } else if (hasQrImageUpdate) {
      resolvedQrImage = qrCodeImage as Image?;
      resolvedQrText = resolvedQrImage != null ? null : this.qrCodeText;
    } else {
      resolvedQrImage = this.qrCodeImage;
      resolvedQrText = this.qrCodeText;
    }

    return BabyModel(
      hospitalRegister: hospitalRegister ?? this.hospitalRegister,
      id: id ?? this.id,
      name: name ?? this.name,
      motherName: motherName ?? this.motherName,
      birthDate: birthDate ?? this.birthDate,
      isActive: isActive ?? this.isActive,
      qrCodeImage: resolvedQrImage,
      qrCodeText: resolvedQrText,
      assignedScale: hasAssignedScaleUpdate ? assignedScale as ScaleModel? : this.assignedScale,
      weightHour: weightHour ?? this.weightHour,
      hasQrCode: hasQr ?? this.hasQrCode,
      scaleId: hasScaleIdUpdate ? scaleId as int? : this.scaleId,
    );
  }
}

