import 'package:flutter/material.dart';

class PrivacySelector extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String startLabel;
  final bool playlist;
  const PrivacySelector({super.key, required this.onChanged, required this.startLabel, required this.playlist});

  @override
  State<PrivacySelector> createState() => _PrivacySelectorState();
}

class _PrivacySelectorState extends State<PrivacySelector>{
  late int _index;

  late List<_Option> _options;

  @override
  void initState() {
    super.initState();

    _options = [
      _Option(
        image: const AssetImage('assets/icons/public_icon.png'),
        label: 'Public',
        width: 35,
        height: 25,
      ),
      if (!widget.playlist)
        _Option(
          image: const AssetImage('assets/icons/friends_only_icon.png'),
          label: 'Friends Only',
          width: 25,
          height: 25,
        ),
      _Option(
        image: const AssetImage('assets/icons/private_icon.png'),
        label: widget.playlist ? 'Private' : 'My Eyes Only',
        width: 35,
        height: 25,
      ),
    ];

    _index = _options.indexWhere(
      (o) => o.label.toLowerCase() == widget.startLabel.toLowerCase(),
    );

    if (_index == -1) _index = 0;
  }
  
  void _next() {
    setState(() {
      _index = (_index + 1) % _options.length;
    });

    widget.onChanged(_options[_index].label);
  }

  @override
  Widget build(BuildContext context) {
    final option = _options[_index];

    return GestureDetector(
      onTap: _next,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Image(
              key: ValueKey(_index),
              image: option.image,
              width: option.width,
              height: option.height,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              option.label,
              key: ValueKey(option.label),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Option {
  final ImageProvider image;
  final String label;
  final double width;
  final double height;

  const _Option({
    required this.image,
    required this.label,
    required this.width,
    required this.height
  });
}