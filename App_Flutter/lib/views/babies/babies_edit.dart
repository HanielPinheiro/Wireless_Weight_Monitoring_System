import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/baby.dart';
import '../../repository/design/button_styles.dart';
import '../../repository/design/fonts.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/providers/baby_provider.dart';
import '../../repository/services/qrcode_service.dart';
import '../../repository/widgets/elements.dart';

class BabiesEdit extends StatefulWidget {
  const BabiesEdit({super.key, required this.baby});

  final BabyModel baby;

  @override
  State<BabiesEdit> createState() => _BabiesEditState();
}

class _BabiesEditState extends State<BabiesEdit> {
  late TextEditingController _hospIdController;
  late TextEditingController _nameIdController;
  late TextEditingController _nameMotherController;
  late TextEditingController _birthDateController;
  late TextEditingController _weightTimeController;

  Uint8List? _currentImage;
  String? _currentText;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _hospIdController = TextEditingController(text: widget.baby.hospitalRegister);
    _nameIdController = TextEditingController(text: widget.baby.name ?? '');
    _nameMotherController = TextEditingController(text: widget.baby.motherName ?? '');
    _weightTimeController = TextEditingController(text: widget.baby.weightHour != null ? widget.baby.weightHour! : 'Sem horário definido');
    _birthDateController = TextEditingController(text: widget.baby.birthDate != null ? dateFormatter_objToDb.format(widget.baby.birthDate!) : '');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadQrImg();
    });
  }

  Future<void> _loadQrImg() async {
    if (widget.baby.qrCodeText != null) {
      setState(() {
        _currentText = widget.baby.qrCodeText;
      });
    }

    // Load QR image if baby has one
    if (widget.baby.hasQrCode && widget.baby.id != null) {
      try {
        final baby = await context.read<BabyProvider>().getBabyById(context, widget.baby.id!);
        if (baby.qrCodeImage != null) {
          final qrCodeBytes = await imageToUint8List(baby.qrCodeImage!);
          setState(() {
            _currentImage = qrCodeBytes;
          });
        }
      } catch (e) {
        print('Error loading QR image: $e');
      }
    }
  }

  @override
  void dispose() {
    _hospIdController.dispose();
    _nameIdController.dispose();
    _nameMotherController.dispose();
    _birthDateController.dispose();
    _weightTimeController.dispose();
    super.dispose();
  }

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

  Widget _qrIdData() {
    return Column(children: [
      Text("ID do Qr Code", style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      Text(_currentText!, style: titleLarge.copyWith(color: Theme.of(context).colorScheme.primary)),
      SizedBox(height: 10),
    ]);
  }

  Widget _buildImageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: _showImageSourceDialog,
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Column(
            children: [
              // Show current image
              if (_currentImage != null && _currentText == null) // Show scanned text if available
                Container(constraints: BoxConstraints(maxHeight: 120, maxWidth: 120), child: Image.memory(_currentImage!)),
              // Show scanned text if available
              if (_currentText != null && _currentText!.isNotEmpty) _qrIdData(),
              //Show  placeholder
              if (_currentImage == null && _currentText == null) // Show placeholder
                Placeholder(color: Colors.grey, strokeWidth: 2.0, fallbackWidth: 120, fallbackHeight: 120),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElementsOfViews.SimpleButton(context, "Alterar", _showImageSourceDialog),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione a fonte'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Tirar foto'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    }),
                ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: const Text('Escanear QR Code'),
                    onTap: () {
                      Navigator.pop(context);
                      _readQrCode(context);
                    }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetControllers() {
    _hospIdController.clear();
    _nameIdController.clear();
    _nameMotherController.clear();
    _birthDateController.clear();
    _weightTimeController.clear();
  }

  Future<void> _update() async {
    if (_hospIdController.text.isEmpty || _nameIdController.text.isEmpty || _nameMotherController.text.isEmpty || _birthDateController.text.isEmpty || _weightTimeController.text.isEmpty) {
      await showDialog(context: context, builder: (context) => AlertDialog(title: Text("Erro de requisição"), content: Text("Há campos vazios!")));
      return;
    }

    try {
      final newBaby = widget.baby.copyWith(
        id: widget.baby.id,
        hospitalRegister: _hospIdController.text,
        name: _nameIdController.text,
        motherName: _nameMotherController.text,
        birthDate: dateFormatter_objToDb.parse(_birthDateController.text),
        qrCodeText: Nullable(_currentText),
        weightHour: _weightTimeController.text,
      );

      final _babyProvider = context.read<BabyProvider>();
      await _babyProvider.updateBaby(context, newBaby);

      if (_currentText == null && _currentImage != null) {
        await _babyProvider.updateQrCode(context, widget.baby.id!, _currentImage);
      } else if (_currentText != null && _currentImage == null) {
        await _babyProvider.updateQrCode(context, widget.baby.id!, null);
      }
      await showDialog(context: context, builder: (context) => AlertDialog(content: Text("Dados do Bebê [${widget.baby.id}] atualizados com sucesso!")));
      Navigator.pop(context);
    } catch (e) {
      await showDialog(context: context, builder: (context) => AlertDialog(title: Text("Erro de requisição"), content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.SimpleAppBar(context, 'Dados do Bebê'),
            body: ListView(padding: const EdgeInsets.symmetric(horizontal: 8.0), children: <Widget>[
              Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                const SizedBox(height: 20.0),
                _buildImageSection(),
                const SizedBox(height: 20.0),
                ElementsOfViews.InputWithController(context, _hospIdController, 'Registro Hospitalar', 'Código/registro do bebê no hospital', Icon(Icons.numbers, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _nameIdController, 'Nome do paciente', 'Digite o nome do bebê', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _nameMotherController, 'Nome da mãe do paciente', 'Digite o nome da mãe do bebê', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12.0),
                ElementsOfViews.DateInput(context, _birthDateController, 'Data de Nascimento do Paciente', 'Digite os números'),
                const SizedBox(height: 12.0),
                ElementsOfViews.InputWithController(context, _weightTimeController, 'Horário(s) da(s) coleta(s) do peso', '', Icon(Icons.abc, color: Theme.of(context).colorScheme.primary), false, true),
                Row(children: [SizedBox(width: 15), ElementsOfViews.SimpleButton(context, "Gerenciar Horários", () async => await ElementsOfViews.ShowTimeManager(context, (newTimes) => setState(() => _weightTimeController.text = newTimes), initialTimes: _weightTimeController.text), false)]),
                const SizedBox(height: 20.0),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  children: <Widget>[ElementsOfViews.SimpleButton(context, "LIMPAR CAMPOS", () => _resetControllers()), const SizedBox(width: 8.0), ElementsOfViews.IconContrastButton(context, Icon(Icons.cloud_upload, color: Colors.black), "ATUALIZAR", () async => await _update())],
                ),
              ])
            ])));
  }
}
