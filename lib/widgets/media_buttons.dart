import 'package:flutter/material.dart' hide Theme;
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/models/theme.dart';
import 'package:provider/provider.dart';

enum RadioType { book, movie, television }

class MediaTypeRadio extends StatelessWidget {
  final RadioType value;
  final ValueChanged<RadioType> onChanged;

  const MediaTypeRadio({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _radio('Movie', RadioType.movie, theme),
        const SizedBox(width: 5),
        _radio('TV', RadioType.television, theme),
        const SizedBox(width: 5),
        _radio('Book', RadioType.book, theme),
      ],
    );
  }

  Widget _radio(String label, RadioType type, Theme theme) {
    return InkWell(
      key: Key('media_type_${type.name}'),
      onTap: () => onChanged(type),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<RadioType>(
            value: type,
            groupValue: value,
            onChanged: (val) => onChanged(val!),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            fillColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return theme.primaryColor;
              }
              return theme.primaryColor;
            }),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
          Text(label, style: TextStyle(
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
