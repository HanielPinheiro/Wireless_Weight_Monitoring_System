import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/scales_provider.dart';
import '../design/fonts.dart';
import '../helper/constants.dart';
import '../widgets/elements.dart';

class BluetoothHelper {
  static const MethodChannel _channel = MethodChannel('bluetooth_helper');
  static const EventChannel _eventChannel = EventChannel('bluetooth_helper_state');

  static Future<bool> isBluetoothOn() async {
    final result = await _channel.invokeMethod<bool>('isBluetoothOn');
    return result ?? false;
  }

  static Stream<bool> get bluetoothStateStream {
    return _eventChannel.receiveBroadcastStream().map((event) => event as bool);
  }
}

class BluefiService extends StatefulWidget {
  final String scannedUUID;

  const BluefiService(this.scannedUUID, {Key? key}) : super(key: key);

  @override
  State<BluefiService> createState() => _BluefiService();
}



class _BluefiService extends State<BluefiService> {
  final _wifiLogin = TextEditingController();
  final _wifiPassword = TextEditingController();
  final _flutterEspBleProvPlugin = FlutterEspBleProv();
  bool _isLoading = true;
  bool _permission = false;
  bool _bleOn = false;
  bool _wifiResult = false;
  String? _provName = null;
  String? _pop = null;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    BluetoothHelper.isBluetoothOn().then((isOn) {
      setState(() {
        _bleOn = isOn;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      BluetoothHelper.bluetoothStateStream.listen((isOn) {
        setState(() {
          _bleOn = isOn;
        });
        if (_permission && _bleOn) {
          setState(() {
            _statusMessage = "";
            _isLoading = false;
          });
        }
      });
      await _getScaleData();
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _wifiLogin.dispose();
    _wifiPassword.dispose();
    super.dispose();
  }

  Future<void> _getScaleData() async {
    final scaleData = await context.read<ScalesProvider>().getScaleDataFromHash(context, widget.scannedUUID);
    _provName = scaleData[0];
    _pop = scaleData[1];

    if (_provName == null || _pop == null) {
      ElementsOfViews.showSimpleDialog(context, "Não é possível realizar o pareamento", "Não foi possível identificar o dispositivo através do BLE.");
      Navigator.pop(context, _wifiResult);
    }
  }

  Future<void> _connectAction() async {
    _wifiResult = await _provisionWifi();
    if (_wifiResult) {
        await ElementsOfViews.showSimpleDialog(context, "Conexão concluída!", 'Balança conectada ao Wi-Fi!');
        Navigator.pop(context,_wifiResult);
    }
  }

  _permissionsError(String error) {
    setState(() {
      _permission = false;
      _isLoading = true;
      _statusMessage = error;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _statusMessage = "Solicitando permissões...";
      _isLoading = true;
    });

    final List<Permission> permissions = [];

    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkVersion = androidInfo.version.sdkInt;

        permissions.add(Permission.location);
        if (sdkVersion >= 31) { // Android 12+ - Novas permissões Bluetooth
          permissions.add(Permission.bluetoothScan);
          permissions.add(Permission.bluetoothConnect);
          permissions.add(Permission.bluetoothAdvertise);
        } else // Android 11 ou inferior - Permissões antigas
          permissions.add(Permission.bluetooth);
      } else if (Platform.isIOS) {
        permissions.add(Permission.bluetooth);
        permissions.add(Permission.locationWhenInUse);
      }
    } catch (e) {
      _permissionsError('Erro ao solicitar permissões: $e');
      return;
    }

    bool canProceed = true;
    for (var permission in permissions) {
      final permsStatus = await permission.request();
      if (!permsStatus.isGranted) canProceed = false;
    }

    if (!canProceed) {
      _permissionsError("Permissões negadas ou dispositivo não suporta app, informar suporte!!");
      return;
    }
    if (!_bleOn) {
      ElementsOfViews.showSimpleDialog(context, "Ative seu Bluetooth!!", "Por favor, habilite o Bluetooth do seu celular antes de prosseguir");
      setState(() {
        _permission = true;
        _statusMessage = "Ative seu Bluetooth!!";
      });
    } else { //can connect
      setState(() {
        _permission = true;
        _isLoading = false;
        _statusMessage = "Permissões ativadas!";
      });
    }
  }

  Future<bool> _provisionWifi() async {
    setState(() {
      _isLoading = true;
    });
    final login = _wifiLogin.text;
    final password = _wifiPassword.text;
    if (login.isEmpty || password.isEmpty) {
      await ElementsOfViews.showSimpleDialog(context, "Verifique as credenciais", 'Por favor, verifique se inseriu o nome da rede e a senha');
      return false;
    }

    try {
      setState(() {
        _statusMessage = "Procurando dispositivos...";
      });
      final _prefix = "PW_";
      List<String> bleDevices = await _flutterEspBleProvPlugin.scanBleDevices(_prefix);
      print('Dispositivos encontrados: $bleDevices');
      if (bleDevices.length < 0) return false;
      setState(() {
        _statusMessage = "Dispositivo encontrado.\n Iniciando conexão...";
      });
      bool? success = await _flutterEspBleProvPlugin.provisionWifi(bleDevices[0], _pop!, login, password);
      if (success != true) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Falha ao conectar";
        });
        return false;
      }

      return true;
    } on PlatformException catch (e) {
      print('Erro de plataforma: ${e.message}');
      setState(() {
        _statusMessage = "Erro: ${e.message}";
        _isLoading = false;
      });
      return false;
    } catch (e) {
      print('Erro inesperado: $e');
      setState(() {
        _statusMessage = "Erro inesperado: $e";
        _isLoading = false;
      });
      return false;
    }
  }

  Widget _showConnData() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(10),
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(lbl_wifi_data_br, style: displaySmall.copyWith(color: theme.colorScheme.primary)),
            SizedBox(height: 12),
            ElementsOfViews.InputWithController(context, _wifiLogin, lbl_wifi_login_br, lbl_wifi_login_lbl_br, Icon(Icons.person, color: theme.colorScheme.primary)),
            SizedBox(height: 12),
            ElementsOfViews.InputWithController(context, _wifiPassword, lbl_wifi_pass_br, lbl_login_senha_lbl_br, Icon(Icons.password, color: theme.colorScheme.primary), true),
            SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                icon: Icon(Icons.login, color: theme.colorScheme.primary),
                label: Text(lbl_wifi_btn_connect_br, style: TextStyle(color: theme.colorScheme.primary)),
                onPressed: () async => await _connectAction(),
                style: ElevatedButton.styleFrom(foregroundColor: theme.colorScheme.primary, backgroundColor: theme.colorScheme.onSecondary, elevation: 4.0),
              ),
            )
          ],
        ),
      ),
    );
  }

  _btnActivateBluetooth() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(10),
      color: theme.colorScheme.surface,
      child: Center(
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            icon: Icon(size: 25, Icons.bluetooth, color: theme.colorScheme.primary),
            label: Text(lbl_wifi_btn_ble_permission_br, style: headlineSmall.copyWith(color: theme.colorScheme.primary)),
            onPressed: () async => _requestPermissions(),
            style: ElevatedButton.styleFrom(foregroundColor: theme.colorScheme.primary, backgroundColor: theme.colorScheme.onSecondary, elevation: 4.0),
          ),
        ),
      ),
    );
  }

  _messageArea() {
    return Container(padding: EdgeInsets.all(10), child: Center(child: Text(_statusMessage, textAlign: TextAlign.center, style: displayMedium.copyWith(color: Theme.of(context).colorScheme.primary))));
  }

  _loadScreen() {
    return Scaffold(backgroundColor: Theme.of(context).colorScheme.surface, appBar: ElementsOfViews.SimpleAppBar(context, lbl_connect_scale_to_network_br), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Expanded(flex: 2, child: SizedBox(height: 200)), CircularProgressIndicator(), SizedBox(height: 20), Expanded(flex: 4, child: Text(_statusMessage, textAlign: TextAlign.center, style: displayMedium.copyWith(color: Theme.of(context).colorScheme.primary)))])));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _loadScreen();
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: ElementsOfViews.SimpleAppBar(context, lbl_connect_scale_to_network_br),
        body: Container(
          padding: EdgeInsets.all(10),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(flex: 3, child: _bleOn ? _showConnData() : _btnActivateBluetooth()), Expanded(flex: 1, child: _messageArea())],
          ),
        ),
      ),
    );
  }
}
