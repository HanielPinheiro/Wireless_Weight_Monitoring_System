import 'package:flutter/material.dart';
import 'package:precious_weight/repository/widgets/elements.dart';
import '../../api/user_api.dart';
import '../../repository/design/fonts.dart';
import '../../repository/services/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
          Row(mainAxisAlignment: MainAxisAlignment.start,children: [IconButton(onPressed: () async{Navigator.pop(context);}, icon: Icon(Icons.arrow_back))]),
          ElementsOfViews.InputWithController(context, _usernameController, 'E-mail', 'Digite seu usuário', Icon(Icons.person, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 12.0),
          ElementsOfViews.InputWithController(context, _passwordController, 'Senha', 'Senha', Icon(Icons.password, color: Theme.of(context).colorScheme.primary), true),
          const SizedBox(height: 12.0),
          ElementsOfViews.InputWithController(context, _confirmPasswordController, 'Confirmar Senha', 'Confirmar Senha', Icon(Icons.password, color: Theme.of(context).colorScheme.primary), true),
          const SizedBox(height: 20.0),
          OverflowBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              ElementsOfViews.SimpleButton(context, "LIMPAR", () {_usernameController.clear();_passwordController.clear();_confirmPasswordController.clear();}),
              const SizedBox(width: 8.0),
              ElementsOfViews.IconContrastButton(context, Icon(Icons.send, color: Colors.black), "Resetar Senha", () async {
                if(_usernameController.text == "" || !_usernameController.text.contains("@")) {
                  await showDialog(context: context,builder: (context) =>AlertDialog(title: const Text("Erro"), content: Text("E-mail inválido!")));
                }
                else if(_passwordController.text != _confirmPasswordController.text) {
                  await showDialog(context: context,builder: (context) =>AlertDialog(title: const Text("Erro"), content: Text("As senhas não são iguais")));
                }
                else if(_passwordController.text.length < 8){
                  await showDialog(context: context,builder: (context) =>AlertDialog(title: const Text("Erro"), content: Text("A senha deve ter pelo menos 8 caracteres!")));
                }
                else {
                  await SafeApi.call(
                      context: context,
                      apiCall: () async {await _userApi.ResetPassword(_usernameController.text, _passwordController.text);},
                      onSuccess: () async {
                        await showDialog(context: context,builder: (context) =>AlertDialog(title: const Text("Senha Resetada"), content: Text("Redefinição de senha concluída, faça login para acessar!")));
                        Navigator.pop(context);
                      }
                  );
                }
              })
            ],
          ),
        ],
      ),
    ])));
  }
}
