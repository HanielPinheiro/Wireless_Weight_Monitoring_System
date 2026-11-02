import 'package:flutter/material.dart';
import 'package:precious_weight/repository/providers/scales_provider.dart';
import 'package:provider/provider.dart';

import 'repository/providers/baby_provider.dart';
import 'repository/design/theme.dart';
import 'views/login/login.dart';

void main() => runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BabyProvider()),
        ChangeNotifierProvider(create: (_) => ScalesProvider()),
      ],
      child:PreciousWeightApp()
    ),
);

class PreciousWeightApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precious Weight',
      themeMode: ThemeMode.system,
      theme: PreciousWeightTheme.light(),
      darkTheme: PreciousWeightTheme.dark(),
      home: const LoginPage(),
    );
  }
}