import 'package:flutter/material.dart';
import '../../api/user_api.dart';
import '../../repository/widgets/elements.dart';
import '../../views/babies/babies.dart';
import '../../views/home/home.dart';
import '../../views/login/login.dart';
import '../../views/logs/logs.dart';
import '../../views/scales/scales.dart';
import '../design/fonts.dart';
import '../helper/constants.dart';

class MenuManager extends StatefulWidget {
  @override
  _MenuManagerState createState() => _MenuManagerState();
}

class _MenuManagerState extends State<MenuManager> {
  int currentPageIndex = 0; // Index of the selected bottom nav item

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: ElementsOfViews.MenuAppBar(context, "Olá ${UserApi().user!.organization}", 'SAIR', Icon(Icons.logout, semanticLabel: 'SAIR', color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onPrimary), () {
              UserApi().Logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
            }),
            body: <Widget>[HomePage(), BabiesPage(), ScalesPage(), LogsPage()][currentPageIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0)), boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.primary, blurRadius: 2, offset: Offset(0, -1)),
              ]),
              child: NavigationBar(
                  onDestinationSelected: (int index) {
                    setState(() => currentPageIndex = index);
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  indicatorColor: Theme.of(context).colorScheme.onSecondary,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  labelTextStyle: WidgetStateProperty.all(bodyLarge.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 13.0)),
                  selectedIndex: currentPageIndex,
                  destinations: <Widget>[
                    NavigationDestination(
                      selectedIcon: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
                      icon: Icon(Icons.home_outlined, color: Theme.of(context).colorScheme.primary),
                      label: lbl_home_br,
                    ),
                    NavigationDestination(
                      selectedIcon: Icon(Icons.child_care, color: Theme.of(context).colorScheme.primary),
                      icon: Icon(Icons.child_care_outlined, color: Theme.of(context).colorScheme.primary),
                      label: lbl_babies_br,
                      // icon: Badge(child: Icon(Icons.bedroom_baby, color: Theme.of(context).colorScheme.primary)),
                    ),
                    NavigationDestination(
                      selectedIcon: Icon(Icons.scale, color: Theme.of(context).colorScheme.primary),
                      icon: Icon(Icons.scale_outlined, color: Theme.of(context).colorScheme.primary),
                      label: lbl_scales_br,
                    ),
                    NavigationDestination(
                      selectedIcon: Icon(Icons.note_alt, color: Theme.of(context).colorScheme.primary),
                      icon: Icon(Icons.note_alt_outlined, color: Theme.of(context).colorScheme.primary),
                      label: lbl_logs_br,
                    ),
                  ],
                  surfaceTintColor: Colors.transparent,
                  elevation: 1,
                  height: 70),
            )));
  }
}
