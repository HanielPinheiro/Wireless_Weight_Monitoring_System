import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/weight_api.dart';
import '../../repository/design/button_styles.dart';
import '../../repository/providers/scales_provider.dart';
import '../../models/scales.dart';
import '../../models/baby.dart';
import '../../repository/design/fonts.dart';
import '../../repository/helper/conversions.dart';
import '../../repository/services/bluefi_service.dart';
import '../../repository/services/api_service.dart';
import '../../repository/widgets/elements.dart';
import '../../repository/providers/baby_provider.dart';
import 'scales_babies.dart';

/**
 * Use context.watch<T>() when the widget needs to rebuild upon provider changes.
 * Use context.read<T>() when accessing provider data without triggering a rebuild (e.g., in event handlers).
 * Use Consumer<T> for more granular control over widget rebuilds, affecting only a specific subtree.
 * Prefer context.watch<T>() and context.read<T>() over Provider.of<T>(context) for modern Flutter development with the provider package.
 */

class ScaleDetails extends StatefulWidget {
  ScaleDetails({super.key, required this.id});

  final int id;

  @override
  State<ScaleDetails> createState() => _ScaleDetailsState();
}

class _ScaleDetailsState extends State<ScaleDetails> {
  bool _isLoading = true;
  ScaleModel? _currentScale;
  bool _scaleActive = false;
  bool _hasBaby = false;

  bool get _isScaleOnline => _scaleActive ? _currentScale?.isConnected ?? false : false;

  String get _wifiStrength => _scaleActive ? _currentScale?.wifiStrength.toString() ?? "0" : "0";

  bool get _canReceiveMqttCommands => _isScaleOnline && _scaleActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    //Capture provider references safely BEFORE any async gaps
    final scalesProvider = context.read<ScalesProvider>();
    final babiesProvider = context.read<BabyProvider>();

    ScaleModel? scale = await scalesProvider.getScaleById(context, widget.id);
    bool result = false;

    if(scale.isConnected) {
      try {
        await scalesProvider.requestWifiStrength(context, widget.id);
        result = true;
      } catch (e) {
        scalesProvider.updateScaleConnectivity (widget.id, false);
        scale = scale.copyWith(isConnected: false);
      }
    }

    BabyModel? baby;
    if (scale.babyId != null) {
      baby = await babiesProvider.getBabyById(context, scale.babyId!);
    }

    //Always check mounted BEFORE accessing setState or variables tied to it
    if (!mounted) return;
    setState(() {
      _currentScale = scale!.copyWith(assignedBaby: baby);
      _scaleActive = scale.status == 1 && result;
      _hasBaby = scale.babyId != null;
      _isLoading = false;
    });
  }

  Future<void> _linkBabyToScale(BabyModel baby) async {
    final result = await ElementsOfViews.showConfirmDialog(context, "Confirmação", "Você confirma a associação do bebê ${baby.name!} com a balança ${_currentScale!.id}");
    if (!result) return;
    await context.read<ScalesProvider>().setOrUnsetBaby(context, _currentScale!.id, baby_code: baby.id!.toString());
    await _refreshBabyCacheAndScreen();
  }

  Future<void> _unlinkBabyFromScale() async {
    final _baby = _currentScale!.assignedBaby!;
    final result = await ElementsOfViews.showConfirmDialog(context, 'Bebê Associado', "Nome do bebê: ${_baby.name}\nNome da mãe: ${_baby.motherName}\nData de nascimento: ${dateFormatter_objToDb.format(_baby.birthDate!)}", btnCancelLbl: 'Fechar', btnConfirmLbl: "Desassociar");
    if (!result) return;
    await context.read<ScalesProvider>().setOrUnsetBaby(context, _baby.scaleId!);
    await _refreshBabyCacheAndScreen();
  }

  Future<void> _refreshBabyCacheAndScreen() async {
    await context.read<BabyProvider>().loadBabies(); //força atualizar o cache dos bebes
    await _loadData();
  }

  Future<void> _runScaleCommand({required String loadingTitle, required String successTitle, required Future<String> Function() command}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(title: Text(loadingTitle), content: const SizedBox(height: 72, child: Center(child: CircularProgressIndicator()))),
    );

    try {
      final raw = await command();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await ElementsOfViews.showApiAnswerDialog(context, successTitle, raw.isEmpty ? 'Solicitação enviada com sucesso.' : raw, contentFontSize: 25);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _measureWeightNow() async {
    if (!_canReceiveMqttCommands) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text("Lendo peso..."),
        content: SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
      ),
    );

    String rawWeight;
    try {
      rawWeight = await context.read<ScalesProvider>().requestWeightNow(context, _currentScale!.id);
    } catch (_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final weightValue = double.tryParse(rawWeight.trim());
    if (weightValue == null) {
      await ElementsOfViews.showSimpleDialog(context, "Erro", "Valor de peso inválido retornado: $rawWeight");
      return;
    }

    final weightDisplay = "${weightValue.toStringAsFixed(2)} g";

    final saved = await ElementsOfViews.showWeightResultDialog(
      context,
      weightDisplay,
      showSaveButton: _hasBaby,
      onSave: () async {
        return await SafeApi.call<bool>(
          context: context,
          apiCall: () => WeightApi().saveWeight(
            babyId: _currentScale!.babyId!,
            scaleId: _currentScale!.id,
            weightValue: weightValue,
          ),
        );
      },
    );

    if (saved && mounted) {
      await ElementsOfViews.showSimpleDialog(context, "Sucesso", "Peso salvo no banco de dados!");
    }
  }

  Future<void> _tareScale() async {
    if (!_canReceiveMqttCommands) return;
    await _runScaleCommand(
      loadingTitle: 'Solicitando tara...',
      successTitle: 'Realizar Tara',
      command: () => context.read<ScalesProvider>().requestTare(context, _currentScale!.id),
    );
  }

  Future<void> _connectToWifiUsingBle() async {
    final isWifiConnected = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => BluefiService(_currentScale!.hash)));
    if (isWifiConnected!) _currentScale!.isConnected = true;
  }

  Future<void> _changeWifi() async {
    if (!_canReceiveMqttCommands) return;
    await _runScaleCommand(
      loadingTitle: 'Solicitando troca de Wi-Fi...',
      successTitle: 'Trocar Wi-Fi',
      command: () => context.read<ScalesProvider>().requestChangeWifi(context, _currentScale!.id),
    );
    _currentScale!.isConnected = false;

    await _connectToWifiUsingBle();
  }

  Widget _withoutBaby() {
    return ElementsOfViews.GroupChildrenInRow([
      ElementsOfViews.SimpleButton(context, _scaleActive ? "Inativar Balança" : "Ativar Balança", () async {
        await context.read<ScalesProvider>().enableOrDisableScale(context, _currentScale!);
        await _loadData();
      }, false, _hasBaby),
      ElementsOfViews.SimpleButton(context, "Associar Balança a um Bebê", () async {
        final baby = await Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleBabies(scale: _currentScale)));
        if (baby != null) await _linkBabyToScale(baby);
      }, false, !_scaleActive)
    ]);
  }

  _wrapText(BuildContext context, String text) {
    return Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: Text(text, style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)));
  }

  Widget _showBabyDetails() {
    return ElementsOfViews.ResponsiveCard(context,[
      if (_currentScale!.assignedBaby!.qrCodeImage != null) Container(child: _currentScale!.assignedBaby!.qrCodeImage, constraints: BoxConstraints(maxWidth: 120)),
      SizedBox(width: 10),
      Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(height: 20),
            Text("Bebê na Balança", style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 24)),
            SizedBox(height: 20),
            _wrapText(context, "Nome: ${_currentScale!.assignedBaby!.name!}"),
            _wrapText(context, "Nome da mãe: ${_currentScale!.assignedBaby!.motherName!}"),
            _wrapText(context, "Data de Nascimento: ${dateFormatter_objToDb.format(_currentScale!.assignedBaby!.birthDate!)}"),
            SizedBox(height: 20),
            ElementsOfViews.SimpleButton(context, "Trocar Bebê de Balança", () async {
              await _unlinkBabyFromScale();
            }, false, !_scaleActive),
            SizedBox(height: 20),
          ])),
    ]
    );
  }

  Widget _flexMeasureWeight() {
    final isActionDisabled = !_scaleActive || !_isScaleOnline;
    return Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
      ElementsOfViews.SimpleButton(context, "Medir Peso Agora", () async {
        await _measureWeightNow();
      }, false, isActionDisabled),
      ElementsOfViews.SimpleButton(context, "Realizar Tara", () async {
        await _tareScale();
      }, false, isActionDisabled),
    ]);
  }

  Widget _flexWifiStrength() {
    final wifiIcon = _isScaleOnline ? Icons.wifi : Icons.wifi_off;
    final wifiIconColor = _isScaleOnline ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.error;

    return ElementsOfViews.GroupChildrenInRow([
      ElementsOfViews.GroupChildrenInColumn([
        ElementsOfViews.NormalInputText(context, _isScaleOnline ? "Wifi Conectado " : "Wifi Desconectado", 17),
        ElementsOfViews.NormalInputText(context, _isScaleOnline ? _currentScale!.connectedAt : _currentScale!.disconnectedAt, 12),
      ], CrossAxisAlignment.start),
      ElementsOfViews.GroupChildrenInRow([
        Icon(wifiIcon, color: wifiIconColor, size: 36),
        SizedBox(width: 5),
        ElementsOfViews.NormalInputText(context, _wifiStrength, 17),
      ])
    ]);
  }

  Widget _showScaleCommands() {
    return ElementsOfViews.ResponsiveCard(context, [
      _flexWifiStrength(),
      _isScaleOnline
          ? ElementsOfViews.PwIconButton(context, Icon(Icons.bluetooth, color: Theme.of(context).colorScheme.primary, size: 36), "Trocar Wi-Fi via BLE", false, () async {
        await _changeWifi();
      })
          : ElementsOfViews.PwIconButton(context, Icon(Icons.bluetooth, color: Theme.of(context).colorScheme.primary, size: 36), "Conectar ao Wi-Fi via BLE", false, () async {
        await _connectToWifiUsingBle();
      }),
      _flexMeasureWeight()
    ]);
  }

  Widget _showScaleDetails() {
    return ElementsOfViews.ResponsiveCard(context, [_wrapText(context, "Código Hash: "), _wrapText(context, _currentScale!.hash), _wrapText(context, "Estado da balança: ${ScaleModel.ScaleOperation(_currentScale!.status)}")]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentScale == null) {
      return AlertDialog(content: Text('Scale not found'));
    }

    return Scaffold(
      appBar: ElementsOfViews.SimpleAppBar(context, 'Dados da Balança'),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          !_hasBaby ? Expanded(flex: 1, child: _withoutBaby()) : Row(),
          SizedBox(height: 20),
          Expanded(flex: 2, child: _showScaleDetails()),
          SizedBox(height: 20),
          Expanded(flex: 3, child: _showScaleCommands()),
          SizedBox(height: 20),
          _hasBaby ? Expanded(flex: 3, child: _showBabyDetails()) : Row(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
