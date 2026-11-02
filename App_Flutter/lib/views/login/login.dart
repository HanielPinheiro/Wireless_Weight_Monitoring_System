import 'package:flutter/material.dart';
import 'package:precious_weight/repository/widgets/elements.dart';
import 'package:precious_weight/views/login/cadastro.dart';
import 'package:precious_weight/views/login/reset_senha.dart';
import '../../api/user_api.dart';
import '../../repository/design/fonts.dart';
import '../../repository/helper/constants.dart';
import '../../repository/services/api_service.dart';
import '../../repository/widgets/menu.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userApi = new UserApi();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: ListView(padding: const EdgeInsets.symmetric(horizontal: 8.0), children: <Widget>[
      const SizedBox(height: 80.0),
      Column(
        children: <Widget>[
          Image.asset("assets/imgs/logo.png", fit: BoxFit.fitWidth),
          const SizedBox(height: 16.0),
          RichText(textAlign: TextAlign.center, text: TextSpan(children: [TextSpan(text: 'Precious ', style: notosans_50.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onPrimary)), TextSpan(text: 'Weight', style: caprasimo_50.copyWith(color: Theme.of(context).colorScheme.onSecondary))])),
          const SizedBox(height: 120.0),
          ElementsOfViews.InputWithController(context, _usernameController, lbl_login_email_br, lbl_login_email_lbl_br, Icon(Icons.person, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 12.0),
          ElementsOfViews.InputWithController(context, _passwordController, lbl_login_senha_br, lbl_login_senha_lbl_br, Icon(Icons.password, color: Theme.of(context).colorScheme.primary), true),
          const SizedBox(height: 20.0),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: <Widget>[
                ElementsOfViews.SimpleButton(context, "LIMPAR", () {
                  _usernameController.clear();
                  _passwordController.clear();
                }),
                const SizedBox(width: 8.0),
                ElementsOfViews.IconContrastButton(context,Icon(Icons.login, color: Colors.black),"ENTRAR",
                  () async {
                    await SafeApi.call(context: context,
                        apiCall: () async {await _userApi.Login(_usernameController.text, _passwordController.text);},
                      onSuccess: () async {Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MenuManager()));}
                    );
                  }
                )
            ],
          ),
          const SizedBox(height: 50.0),
          Row(mainAxisAlignment:MainAxisAlignment.center, children:[
            TextButton(onPressed: () async {Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroPage()));}, child: const Text('Cadastro')),
            TextButton(onPressed: () async {Navigator.push(context, MaterialPageRoute(builder: (context) => ResetPasswordPage()));}, child: const Text('Resetar Senha'))
          ]),
        ],
      ),
    ])));
  }
}
