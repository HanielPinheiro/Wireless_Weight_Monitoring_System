import 'package:flutter/material.dart';

const EdgeInsets top_30 = EdgeInsets.fromLTRB(0, 30, 0, 0);
const EdgeInsets top_40 = EdgeInsets.fromLTRB(0, 40, 0, 0);
const EdgeInsets top_50 = EdgeInsets.fromLTRB(0, 50, 0, 0);
const EdgeInsets all = EdgeInsets.all(20);

class MyButtonStyles {
  ButtonStyle GetLogoutButtonStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      backgroundColor: colorScheme.surface,
      padding: EdgeInsets.zero,
      minimumSize: Size.fromWidth(100),
      maximumSize: Size.fromWidth(100),
      side: BorderSide(
        color: colorScheme.primary, width: 1.5,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class MyDecorations {
  InputDecoration GetInputDecoration(BuildContext context, [String? labelText, String? hintText, Widget? _icon = null]) {
    return InputDecoration(
        prefixIcon: _icon,
        labelText: labelText,
        labelStyle: TextStyle(color: Theme
            .of(context)
            .colorScheme
            .primary),
        hintText: hintText,
        hintStyle: TextStyle(color: Theme
            .of(context)
            .colorScheme
            .primary),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme
            .of(context)
            .colorScheme
            .primary)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme
            .of(context)
            .colorScheme
            .secondary))
    );
  }

  BoxDecoration GetBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.primary),
      borderRadius: BorderRadius.circular(15),
    );
  }
}