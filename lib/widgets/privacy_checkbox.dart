import 'package:flutter/material.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class SingleCheckboxSet extends StatefulWidget {
  final void Function(String?)? onChanged;

  const SingleCheckboxSet({super.key, this.onChanged});

  @override
  _SingleCheckboxSetState createState() => _SingleCheckboxSetState();
}

class _SingleCheckboxSetState extends State<SingleCheckboxSet> {
  String? selected = "Public";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckboxOption("Public"),
        _buildCheckboxOption("Friends Only"),
        _buildCheckboxOption("My Eyes Only"),
      ],
    );
  }

  Widget _buildCheckboxOption(String option) {
    final theme = context.watch<ThemeController>().currentTheme;
  return SizedBox(
    height: 32,
    child: Row(
      children: [
        Checkbox(
          key: Key('privacy_checkbox_${option}'),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
          value: selected == option,
          onChanged: (_) {
            setState(() {
              selected = option;
            });
            widget.onChanged?.call(selected);
          },
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.black;
            }
            return Colors.white;
          }),
          checkColor: Colors.white,
          side: BorderSide(color: theme.primaryColor, width: 2),
        ),
        const SizedBox(width: 4),
        Text(option, style: TextStyle(
          fontFamily: theme.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),),
      ],
    ),
  );
  }
}
