import 'package:flutter/material.dart';
import '../design/button_styles.dart';
import '../design/fonts.dart';

class ElementsOfViews {
  static Widget ScanButton(BuildContext context, String label, String lbl_img, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        onTap: onTap, // Clickable behavior
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Row(
            children: [
              Image.asset("assets/imgs/$lbl_img", width: 80, height: 80, fit: BoxFit.cover),
              SizedBox(width: 12),
              Expanded(child: Text(label, style: amaranth_29.copyWith(color: Theme.of(context).colorScheme.primary))),
            ],
          ),
        ),
      ),
    );
  }

  static showSimpleDialog(BuildContext context, String title, String content, {String? btnCancelLbl, String? btnConfirmLbl}) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // user must tap a button
      builder: (BuildContext context) {
        return AlertDialog(title: Text(title), content: Text(content), actions: [
          SimpleButton(context, "Ok", () {
            Navigator.of(context).pop();
          })
        ]);
      },
    );
  }

  static showApiAnswerDialog(BuildContext context, String title, String content, {double? contentFontSize, String? btnCancelLbl, String? btnConfirmLbl}) async {
    final textTheme = Theme.of(context).textTheme;
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title, style: textTheme.bodyMedium?.copyWith(fontSize: 30)),
            content: contentFontSize != null ? Text(content, style: textTheme.bodyMedium?.copyWith(fontSize: contentFontSize)) : Text(content),
            actions: [
              SimpleButton(context, "Ok", () {
                Navigator.of(context).pop();
              })
            ],
          );
        });
  }

  static Future<bool> showConfirmDialog(BuildContext context, String title, String content, {String? btnCancelLbl, String? btnConfirmLbl}) async {
    final ans = await showDialog(
      context: context,
      barrierDismissible: false, // user must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            SimpleButton(context, btnCancelLbl ?? "Cancelar", () {
              Navigator.of(context).pop(false);
            }),
            SimpleButton(context, btnConfirmLbl ?? "Confirmar", () {
              Navigator.of(context).pop(true);
            }),
          ],
        );
      },
    );
    return ans;
  }

  static Future<bool> showWeightResultDialog(BuildContext context,String weightDisplay, {bool showSaveButton = false,Future<bool> Function()? onSave}) async {
    bool saving = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text("Peso Medido", style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontSize: 30)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(weightDisplay, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontSize: 32)),
                  const SizedBox(height: 20),
                  if (saving) const CircularProgressIndicator(),
                ],
              ),
              actions: [
                SimpleButton(ctx, "Fechar", saving ? null : () => Navigator.of(ctx).pop(false)),
                if (showSaveButton)
                  SimpleButton(ctx, "Salvar peso no BD", saving ? null : () async {
                    setDialogState(() => saving = true);
                    try {
                      final ok = await onSave?.call() ?? false;
                      if (ok && ctx.mounted) Navigator.of(ctx).pop(true);
                    } finally {
                      if (ctx.mounted) setDialogState(() => saving = false);
                    }
                  })
              ]
            );
          },
        );
      }
    );
    return result ?? false;
  }

  static Widget ScanButtonNoImage(BuildContext context, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        onTap: onTap, // Clickable behavior
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(child: Text(textAlign: TextAlign.center, label, style: amaranth_29.copyWith(color: theme.colorScheme.primary))),
          ]),
        ),
      ),
    );
  }

  static Widget CardToList(BuildContext context, IconData icon, String title, String subtitle, VoidCallback detailsScreen) {
    return Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 5,
        shadowColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
            onTap: detailsScreen,
            child: ListTile(
              leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
              title: Text(title, style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary)),
              subtitle: Text(subtitle, style: bodyLarge.copyWith(color: Theme.of(context).colorScheme.primary)),
            )));
  }

  static Widget CardToText(BuildContext context, String label, {Color? bgColor, Color? fgColor, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Card(
        elevation: 5,
        shadowColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        color: bgColor ?? Theme.of(context).colorScheme.surface,
        child: Container(
          padding: EdgeInsets.all(9),
          alignment: Alignment.center, // Centers the text inside the card
          child: Text(
            label,
            style: amaranth_29.copyWith(color: fgColor ?? Theme.of(context).colorScheme.primary, fontSize: fontSize ?? 29),
            textAlign: TextAlign.center, // Ensures text alignment
          ),
        ),
      ),
    );
  }

  static PreferredSizeWidget MenuAppBar(BuildContext context, String title, String label, Icon? _icon, VoidCallback action) {
    return AppBar(
        title: Text(title, style: headlineMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onPrimary)),
        shape: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid)),
// foregroundColor: Theme.of(context).brightness == Brightness.dark? Colors.white: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: <Widget>[
          ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 100, minHeight: 40, maxHeight: 40),
              child: OutlinedButton.icon(
                icon: _icon ?? const SizedBox.shrink(),
                label: Text(
                  label,
                  style: headlineSmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onPrimary),
                ),
                style: MyButtonStyles().GetLogoutButtonStyle(context),
                onPressed: action,
              ))
        ]);
  }

  static PreferredSizeWidget SimpleAppBar(BuildContext context, String title) {
    return AppBar(
      title: Text(title, style: displayMedium.copyWith(color: Theme.of(context).colorScheme.primary)),
      shape: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid)),
      foregroundColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  static Widget InputWithController(BuildContext context, TextEditingController _controller, String labelText, String hintText, Icon _icon, [bool isPassword = false, bool isReadOnly = false]) {
    if (!isPassword) {
      return TextField(
        controller: _controller,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        decoration: MyDecorations().GetInputDecoration(context, labelText, hintText, _icon),
        readOnly: isReadOnly,
        obscureText: false,
      );
    }

    var obscureText = true;
    return StatefulBuilder(
      builder: (context, setState) {
        final colorScheme = Theme.of(context).colorScheme;
        return TextField(
          controller: _controller,
          style: TextStyle(color: colorScheme.primary),
          decoration: MyDecorations().GetInputDecoration(context, labelText, hintText, _icon).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off, color: colorScheme.primary),
                  onPressed: () => setState(() => obscureText = !obscureText),
                ),
              ),
          readOnly: isReadOnly,
          obscureText: obscureText,
        );
      },
    );
  }

  static Future<void> ShowTimeManager(BuildContext context, ValueChanged<String> onSave, {required String initialTimes}) async {
    List<String> times = [];
    if (initialTimes != 'Sem horário definido') times = initialTimes.split(r"$")..removeWhere((t) => t.isEmpty);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: MyDecorations().GetBoxDecoration(context),
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Gerenciar horários', style: displayMedium.copyWith(color: Theme.of(context).colorScheme.primary)),
                SizedBox(height: 20),
                SimpleButton(context, "Adicionar horário", () async {
                  if (times.length > 9) {
                    await showDialog(context: context, builder: (context) => AlertDialog(content: Text("O número máximo de horários é 10!")));
                    return;
                  }
                  final time = await _GetTimePicker(context);
                  if (time != null) {
                    final formattedStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    if (!times.contains(formattedStr)) setState(() => times.add(formattedStr));
                    times.sort();
                  }
                }, true),
                SizedBox(height: 20),
                Expanded(
                    child: ListView.builder(
                        itemCount: times.length, itemBuilder: (ctx, i) => ListTile(leading: Text((i + 1).toString(), textAlign: TextAlign.center, style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary)), title: Text(times[i], textAlign: TextAlign.center, style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary)), trailing: IconButton(icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary), onPressed: () => setState(() => times.removeAt(i)))))),
                SizedBox(height: 20),
                SimpleButton(context, "Voltar", () {
                  onSave(times.join(r"$"));
                  Navigator.pop(context);
                }, true)
              ],
            ),
          );
        },
      ),
    );
  }

  static TimeOfDay _GetTimeOfDayInGmtMinusThree(TimeOfDay? time) {
    final now = DateTime.now();
    final utcTime = time != null ? DateTime(now.year, now.month, now.day, time.hour, time.minute) : DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final gmtMinus3Time = utcTime.subtract(const Duration(hours: 3));
    return TimeOfDay.fromDateTime(gmtMinus3Time);
  }

  static _GetTimePicker(BuildContext context) {
    return showTimePicker(
      context: context,
      initialTime: _GetTimeOfDayInGmtMinusThree(TimeOfDay.now()),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      cancelText: "Cancelar",
      confirmText: "Confirmar",
      helpText: "Insira as horas e minutos:",
      hourLabelText: "Hora",
      minuteLabelText: "Minuto",
      builder: (BuildContext context, Widget? child) {
        final colorScheme = Theme.of(context).colorScheme;
        final style = ButtonStyle(backgroundColor: WidgetStatePropertyAll(colorScheme.surface), foregroundColor: WidgetStatePropertyAll(colorScheme.primary), side: WidgetStatePropertyAll(BorderSide(color: colorScheme.primary, width: 1.5)), elevation: WidgetStatePropertyAll(2));
        return Theme(
          data: Theme.of(context).copyWith(timePickerTheme: TimePickerThemeData(confirmButtonStyle: style, cancelButtonStyle: style, backgroundColor: colorScheme.onSurface, hourMinuteColor: colorScheme.surface, hourMinuteTextColor: colorScheme.primary, helpTextStyle: headlineSmall.copyWith(color: colorScheme.primary))),
          child: Directionality(textDirection: TextDirection.ltr, child: MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!)),
        );
      },
    );
  }

  static Widget DateInput(BuildContext context, TextEditingController _controller, String labelText, String hintText) {
    String _formatDateInput(String input) {
      String digits = input.replaceAll(RegExp(r'[^0-9]'), ''); // Remove all non-digit characters

      if (digits.length >= 3)
        return '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
      else if (digits.length >= 2) return '${digits.substring(0, 2)}/${digits.substring(2)}';

      return digits;
    }

    return TextField(
        controller: _controller,
        keyboardType: TextInputType.datetime,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
          labelText: labelText,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            final formatted = _formatDateInput(value);
            if (formatted != value) _controller.value = _controller.value.copyWith(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
          }
        });
  }

  static Widget SimpleButton(BuildContext context, String _text, [VoidCallback? _onPressed = null, bool contrastColor = false, bool isDisable = false]) {
    return TextButton(
      onPressed: isDisable
          ? null
          : _onPressed != null
              ? _onPressed
              : () {},
      style: TextButton.styleFrom(
        backgroundColor: contrastColor ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.0,
          style: BorderStyle.solid,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      child: Text(_text),
    );
  }

  static Widget IconContrastButton(BuildContext context, Icon _icon, String _text, [VoidCallback? _onPressed = null]) {
    return ElevatedButton.icon(
      icon: _icon,
      label: Text(_text, style: headlineSmall.copyWith(color: Colors.black)),
      onPressed: _onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
        elevation: 4.0,
      ),
    );
  }

  static Widget PwIconButton(BuildContext context, Icon _icon, String _text, bool contrastColor, [VoidCallback? _onPressed = null]) {
    return ElevatedButton.icon(
      icon: _icon,
      label: Text(_text, style: headlineSmall.copyWith(color: contrastColor ? Colors.black : Theme.of(context).colorScheme.primary)),
      onPressed: _onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: contrastColor ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid),
      ),
    );
  }

  static Widget ResponsiveCard(BuildContext context, List<Widget> widgets) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: InkWell(borderRadius: BorderRadius.circular(15), child: Container(padding: EdgeInsets.all(9), decoration: MyDecorations().GetBoxDecoration(context), child: Column(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: widgets))));
  }

  static Widget GroupChildrenInRow(List<Widget> children, [CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center, MainAxisSize mainAxis = MainAxisSize.max, MainAxisAlignment axisAlignment = MainAxisAlignment.spaceEvenly]) {
    return Row(mainAxisSize: mainAxis, mainAxisAlignment: axisAlignment, crossAxisAlignment: crossAxisAlignment, children: children);
  }

  static Widget GroupChildrenInColumn(List<Widget> children, [CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center, MainAxisSize mainAxis = MainAxisSize.max, MainAxisAlignment axisAlignment = MainAxisAlignment.spaceEvenly]) {
    return Column(mainAxisSize: mainAxis, mainAxisAlignment: axisAlignment, crossAxisAlignment: crossAxisAlignment, children: children);
  }

  static Widget NormalInputText(BuildContext _context, String _text, double _fontSize) {
    return Text(_text, style: displaySmall.copyWith(color: Theme.of(_context).colorScheme.primary, fontWeight: FontWeight.normal, fontSize: _fontSize));
  }
}
