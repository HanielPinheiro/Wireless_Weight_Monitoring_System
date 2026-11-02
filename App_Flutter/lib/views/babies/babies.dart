import 'package:flutter/material.dart';
import 'package:precious_weight/models/baby.dart';
import 'package:precious_weight/models/weight.dart';
import 'package:precious_weight/repository/design/fonts.dart';
import 'package:provider/provider.dart';

import '../../repository/providers/baby_provider.dart';
import '../../repository/widgets/elements.dart';
import 'babies_details.dart';
import 'babies_register.dart';

class BabiesPage extends StatefulWidget {
  @override
  _BabiesPageState createState() => _BabiesPageState();
}

class _BabiesPageState extends State<BabiesPage> {
  bool isDischarged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BabyProvider>().loadBabies();
    });
  }

  void _changeState(bool b) {
    setState(() => isDischarged = b);
  }

  Widget _empty() {
    return Column(children:[ Expanded(child:Center(child: Text('Nenhum bebê cadastrado', style: displayLarge.copyWith(color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center,)))]);
  }

  Widget _notEmpty(List<BabyModel> filteredBabies) {
    return ListView(children: [
      Padding(padding: EdgeInsets.all(12.0)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElementsOfViews.SimpleButton(context, "Bebês Ativos", () => _changeState(false), !isDischarged),
          ElementsOfViews.SimpleButton(context, "Bebês Não Ativos", () => _changeState(true), isDischarged),
        ],
      ),
      Padding(padding: EdgeInsets.all(12.0)),
      ...filteredBabies.map((baby) => FutureBuilder<List<WeightModel>?>(
            future: baby.getWeights(),
            builder: (context, snapshot) {
              final text = snapshot.hasData && snapshot.data!.isNotEmpty ? "Último peso: ${snapshot.data!.last.weight.toString()} g" : "Último peso: N/A";
              return ElementsOfViews.CardToList(context, Icons.baby_changing_station, baby.name!, text, () => Navigator.push(context, MaterialPageRoute(builder: (context) => BabiesDetails(id: baby.id!))));
            },
          ))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = context.watch<BabyProvider>();

    if (babyProvider.isLoading) return const Center(child: CircularProgressIndicator());

    final List<BabyModel> filteredBabies = isDischarged ? babyProvider.inactiveBabies : babyProvider.activeBabies;

    return Scaffold(
      body: babyProvider.babies.isEmpty ? _empty() : _notEmpty(filteredBabies),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BabiesRegister(scannedImage: null, scannedText: null))),
        child: Icon(Icons.add),
        tooltip: 'Adicionar novo bebê',
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0), side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
