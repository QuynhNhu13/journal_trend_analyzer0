import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TopicSearchBar extends StatefulWidget {
  final String hintText;
  final String? initialValue;
  final ValueChanged<String> onSearch;

  /// Optional keys for E2E tests: [fieldKey] on the text field, [submitKey] on
  /// the submit button.
  final Key? fieldKey;
  final Key? submitKey;

  const TopicSearchBar({
    super.key,
    required this.hintText,
    required this.onSearch,
    this.initialValue,
    this.fieldKey,
    this.submitKey,
  });

  @override
  State<TopicSearchBar> createState() => _TopicSearchBarState();
}

class _TopicSearchBarState extends State<TopicSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant TopicSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != null &&
        !_focusNode.hasFocus) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSearch(text);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        key: widget.fieldKey,
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submit(),
        style: const TextStyle(
            color: AppColors.ink, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColors.faint),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6),
            child: Material(
              key: widget.submitKey,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _submit,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
