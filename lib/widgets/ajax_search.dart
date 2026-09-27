import 'dart:async';
import 'package:flutter/material.dart';

class AjaxSearchField extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(String query) onSearch;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final String Function(Map<String, dynamic>) displayStringForOption;
  final String hintText;
  final TextEditingController controller;

  const AjaxSearchField({
    super.key,
    required this.onSearch,
    required this.onSelected,
    required this.controller,
    required this.displayStringForOption,
    this.hintText = "Search...",
  });

  @override
  State<AjaxSearchField> createState() => _AjaxSearchFieldState();
}

class _AjaxSearchFieldState extends State<AjaxSearchField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _suppressSearch = false;
  Timer? _debounce;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_suppressSearch) return;

    final query = widget.controller.text.trim();

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.isEmpty) {
        if (!mounted) return;
        setState(() => _suggestions = []);
        return;
      }

      final currentRequestId = ++_searchRequestId;

      if (!mounted) return;
      setState(() => _isSearching = true);

      try {
        final results = await widget.onSearch(query);

        if(currentRequestId != _searchRequestId) return;
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSearching = false);
      }
    });
  }

  Widget? _buildSuffixIcon() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear),
        tooltip: 'Clear',
        onPressed: () {
          widget.controller.clear();
          setState(() => _suggestions = []);
        },
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Input
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            suffixIcon: _buildSuffixIcon(),
          ),
        ),

        // Suggestions Dropdown
        if (_suggestions.isNotEmpty)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                final title = widget.displayStringForOption(item);
                
                final imageUrl = item['image'] as String?;
                Widget poster;

                if (imageUrl != null && imageUrl.startsWith('http')) {
                  poster = 
                  AspectRatio(aspectRatio: 2/3,
                  child: Image.network(imageUrl, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => 
                      Image.asset('assets/media_imgs/placeholder_poster.png',fit: BoxFit.contain,),
                  ));
                }
                else if(item.containsKey('pid')){
                  poster = AspectRatio(aspectRatio: 2/3,
                      child: Image.network(
                        item['image_url'],
                        width: 30,
                        fit: BoxFit.cover,
                      ),
                    );         
                }
                else if(item.containsKey('uid')){
                  poster = ClipRSuperellipse(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        item['profile_pic_url'],
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                    );         
                }
                else {
                  poster = 
                    AspectRatio(aspectRatio: 2/3,
                    child: Image.asset(
                    'assets/media_imgs/placeholder_poster.png',
                    fit: BoxFit.contain,
                  ));
                }

                return ListTile(
                  dense: true,
                  title: Text(title),
                  leading: poster,
                  onTap: () {
                    _suppressSearch = true;
                    widget.controller.text = title;
                    widget.onSelected(item);
                    if (mounted) setState(() => _suggestions = []);
                    FocusScope.of(context).unfocus();

                    Future.delayed(const Duration(milliseconds: 50), () {
                      _suppressSearch = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}