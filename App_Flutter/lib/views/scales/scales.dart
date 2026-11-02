import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/scales.dart';
import '../../repository/design/fonts.dart';
import '../../repository/providers/scales_provider.dart';
import '../../repository/services/bluefi_service.dart';
import '../../repository/services/qrcode_service.dart';
import '../../repository/widgets/elements.dart';
import 'scales_details.dart';

/**
 * Use context.watch<T>() when the widget needs to rebuild upon provider changes.
 * Use context.read<T>() when accessing provider data without triggering a rebuild (e.g., in event handlers).
 * Use Consumer<T> for more granular control over widget rebuilds, affecting only a specific subtree.
 * Prefer context.watch<T>() and context.read<T>() over Provider.of<T>(context) for modern Flutter development with the provider package.
 */

class ScalesPage extends StatefulWidget {
  @override
  _ScalesPageState createState() => _ScalesPageState();
}

class _ScalesPageState extends State<ScalesPage> {
  int isEnabled = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ScalesProvider>().loadScales();
    });
  }

  void _changeState(bool b) {
    final v = b == true ? 1 : 0;
    setState(() => isEnabled = v);
  }

  Widget _empty() {
    return Column(children:[ Expanded(child:Center(child: Text('Nenhuma balança cadastrada', style: displayLarge.copyWith(color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center,)))]);
  }

  Widget _notEmpty(List<ScaleModel> filteredScales) {
    return ListView(
      children: [
        Padding(padding: EdgeInsets.all(12.0)),
        Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElementsOfViews.SimpleButton(context, "Balanças Ativas", () => _changeState(true), isEnabled == 1),
          ElementsOfViews.SimpleButton(context, "Balanças Não Ativas", () => _changeState(false), isEnabled != 1),
        ]),
        Padding(padding: EdgeInsets.all(12.0)),
        ...filteredScales.map((_scale) {
          final operationalStatus = _scale.status == 1 ? 'Operante' : 'Inoperante';
          final connectivityStatus = _scale.isConnected ? 'Online' : 'Offline';
          return ElementsOfViews.CardToList(context, Icons.scale, 'Código da Balança #${_scale.id}', 'Estado: $operationalStatus | Wi-Fi: $connectivityStatus', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ScaleDetails(id:_scale.id)));
          });
        }).toList()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scalesProvider = context.watch<ScalesProvider>();

    if (scalesProvider.isLoading) return const Center(child: CircularProgressIndicator());

    final filteredScales = scalesProvider.scales.where((scale) => scale.status == isEnabled).toList();

    return Scaffold(
      body: scalesProvider.scales.isEmpty ? _empty() : _notEmpty(filteredScales),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ScanQrCode()));
            if (result != null) {
              String qrText = result['text'];
              final id = await context.read<ScalesProvider>().getScaleIdFromHash(context, qrText);
              ScaleModel? scale = null;
              if (id == null) { //balança não está adicionada então adiciona
                scale = await context.read<ScalesProvider>().setNewScale(context, qrText);
                if (scale == null) {
                  await ElementsOfViews.showSimpleDialog(context, "Erro!!", "Falha ao adicionar balança ao BD, reporte ao suporte!");
                  return;
                }
              }

              if(scale != null && !scale.isConnected)
                Navigator.push(context, MaterialPageRoute(builder: (context) => BluefiService(qrText)));
            }
          },
          child: Icon(Icons.add),
          tooltip: 'Adicionar nova balança',
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0), side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid))),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }


}
