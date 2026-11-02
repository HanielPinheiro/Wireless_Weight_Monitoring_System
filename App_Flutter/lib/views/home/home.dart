import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/scales.dart';
import '../../repository/design/fonts.dart';
import '../../repository/providers/scales_provider.dart';
import '../../repository/services/bluefi_service.dart';
import '../../repository/widgets/elements.dart';
import '../../repository/services/qrcode_service.dart';
import '../babies/babies_register.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _currentImage;
  String? _currentText;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _currentImage = bytes;
        _currentText = null;
      });
    }
  }

  Future<void> _readQrCode(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ScanQrCode()));
    if (result != null)
      setState(() {
        _currentText = result['text'];
        _currentImage = result['image'];
      });
  }

  Future<void> _handleScale(BuildContext context)  async {
    final id = await context.read<ScalesProvider>().getScaleIdFromHash(context, _currentText!);
    ScaleModel? scale = null;
    if (id == null) { //balança não está adicionada então adiciona
      scale = await context.read<ScalesProvider>().setNewScale(context, _currentText!);
      if (scale == null) {
        await ElementsOfViews.showSimpleDialog(context, "Erro!!", "Falha ao adicionar balança ao BD, reporte ao suporte!");
        return;
      }
    }

    if(scale != null && !scale.isConnected)
        Navigator.push(context, MaterialPageRoute(builder: (context) => BluefiService(_currentText!)));
  }

  Future<void> _readBabyQr(BuildContext context) async {
    bool qrcode = true;
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Selecione a fonte'),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Tirar foto'),
                    onTap: () {
                      Navigator.pop(context);
                      qrcode = false;
                    }),
                ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: const Text('Escanear QR Code'),
                    onTap: () {
                      Navigator.pop(context);
                      qrcode = true;
                    })
              ])));
        });

    qrcode ? await _readQrCode(context) : await _pickImage();
    Navigator.push(context, MaterialPageRoute(builder: (context) => BabiesRegister(scannedText: _currentText, scannedImage: _currentImage)));
  }

  Future<void> _changeScale(BuildContext context) async {
    await ElementsOfViews.showSimpleDialog(context, "Não implementado", "Falta implementar!");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(children:[Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(text: 'Precious ', style: notosans_50.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onPrimary)),
              TextSpan(text: 'Weight', style: caprasimo_50.copyWith(color: Theme.of(context).colorScheme.onSecondary)),
            ]),
          ),
          SizedBox(height: 65),
          ElementsOfViews.ScanButton(context, "Escanear Bebês", "home_btn1.jpg", () async {
            await _readBabyQr(context);
          }),
          SizedBox(height: 65),
          ElementsOfViews.ScanButton(context, "Escanear Balança", "home_btn2.jpg", () async {
            await _readQrCode(context);
            _currentText == null ?
            await ElementsOfViews.showSimpleDialog(context, "Erro ao escanear QR Code", "Não foi possível ler o conteúdo do QR code!")
                : _handleScale(context);
          }),
          SizedBox(height: 65),
          /*ElementsOfViews.ScanButton(context, "Trocar de Balança", "home_btn3.jpg", () async {
            _changeScale(context);
          }),
          SizedBox(height: 65),*/
        ]))]),
      ),
    );
  }
}


