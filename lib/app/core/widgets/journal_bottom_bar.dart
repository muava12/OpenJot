import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_jot/app/core/constants.dart';
import 'package:open_jot/app/core/theme.dart';

/// Fixed bottom bar for the journal screen: a search pill that expands into a
/// full input on tap, plus a round write button on the right.
///
/// Shape and behaviour follow the approved design; colours come from
/// `AppThemeColors` so the bar respects light/dark theme. No Anchor code is
/// copied — the Dart is written new for OpenJot (Apache-2.0).
///
/// States:
/// - idle: full-width frosted pill with the hint text, round write button.
/// - compact: while the list is scrolled down, the pill collapses into a
///   round icon-only button; tapping it opens search. Driven by the parent
///   ([compact]); ignored while searching.
/// - searching: the pill is the live input, a Cancel pill replaces the write
///   button, and a clear button appears once a query is typed.
class JournalBottomBar extends StatefulWidget {
  /// Fired whenever the search query changes (including when cleared).
  final ValueChanged<String> onQueryChanged;

  /// Fired when the round write button is tapped.
  final VoidCallback onWrite;

  /// Hint shown inside the pill when idle.
  final String hintText;

  /// Collapses the pill into a round icon-only button. Driven by the
  /// journal list's scroll position; ignored while searching.
  final bool compact;

  const JournalBottomBar({
    super.key,
    required this.onQueryChanged,
    required this.onWrite,
    this.hintText = 'Search entries or #tag',
    this.compact = false,
  });

  @override
  State<JournalBottomBar> createState() => _JournalBottomBarState();
}

class _JournalBottomBarState extends State<JournalBottomBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onQueryChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    widget.onQueryChanged(_controller.text);
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
    });
    if (_searching) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      _controller.clear();
      widget.onQueryChanged('');
    }
  }

  void _clearQuery() {
    _controller.clear();
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final pillBgColor = _searching
        ? colors.grey6.withOpacity(0.96)
        : colors.grey6.withOpacity(0.9);
    final borderColor = _searching
        ? Colors.white.withOpacity(0.22)
        : Colors.white.withOpacity(0.12);
    final hintColor = colors.grey1;
    final activeTextColor = colors.grey10;

    // Explicit numeric widths so the compact <-> full transition can
    // animate (a flex/null width snaps instead of animating).
    final controlSize = 46.h;
    final cancelWidth = 72.w;
    final rightWidth = _searching ? cancelWidth : controlSize;
    final fullWidth =
        MediaQuery.sizeOf(context).width - 14.w * 2 - 10.w - rightWidth;
    final isCompact = widget.compact && !_searching;
    final pillWidth = isCompact ? controlSize : fullWidth;

    return SafeArea(
      top: false,
      child: RepaintBoundary(
        child: Container(
          height: 72.h,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: colors.grey7.withOpacity(0.9),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- Search pill (round icon-only button when compact) ---
                GestureDetector(
                  onTap: _searching ? null : _toggleSearch,
                  child: Semantics(
                    button: true,
                    label: AppConstants.searchHintText,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: pillWidth,
                      height: controlSize,
                      decoration: BoxDecoration(
                        color: pillBgColor,
                        borderRadius: BorderRadius.circular(23.r),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: isCompact
                          ? Center(
                              child: Icon(
                                Icons.search,
                                size: 20.sp,
                                color: hintColor,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(23.r),
                              child: SizedBox(
                                width: fullWidth,
                                child: Row(
                                  children: [
                                    SizedBox(width: 16.w),
                                    Icon(
                                      Icons.search,
                                      size: 20.sp,
                                      color: hintColor,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: _searching
                                          ? TextField(
                                              controller: _controller,
                                              focusNode: _focusNode,
                                              style: TextStyle(
                                                color: activeTextColor,
                                                fontSize: 13.sp,
                                                fontFamily: AppConstants.font,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: widget.hintText,
                                                hintStyle: TextStyle(
                                                  color: hintColor
                                                      .withOpacity(0.7),
                                                  fontSize: 13.sp,
                                                  fontFamily:
                                                      AppConstants.font,
                                                ),
                                                border: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                enabledBorder:
                                                    InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.zero,
                                                isCollapsed: true,
                                              ),
                                              onSubmitted: (_) =>
                                                  _focusNode.unfocus(),
                                            )
                                          : Text(
                                              widget.hintText,
                                              style: TextStyle(
                                                color: hintColor,
                                                fontSize: 13.sp,
                                                fontFamily: AppConstants.font,
                                              ),
                                            ),
                                    ),
                                    if (_controller.text.isNotEmpty &&
                                        _searching)
                                      GestureDetector(
                                        onTap: _clearQuery,
                                        child: Padding(
                                          padding:
                                              EdgeInsets.only(right: 12.w),
                                          child: Icon(
                                            Icons.close,
                                            size: 18.sp,
                                            color: hintColor,
                                          ),
                                        ),
                                      ),
                                    if (_searching &&
                                        _controller.text.isEmpty)
                                      SizedBox(width: 12.w),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                // --- Right control: Cancel while searching, write button otherwise ---
                if (_searching)
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Semantics(
                      button: true,
                      label: AppConstants.cancel,
                      child: Container(
                        width: cancelWidth,
                        height: controlSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: pillBgColor,
                          borderRadius: BorderRadius.circular(23.r),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          AppConstants.cancel,
                          maxLines: 1,
                          style: TextStyle(
                            color: activeTextColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppConstants.font,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: widget.onWrite,
                    child: Semantics(
                      button: true,
                      label: AppConstants.addEntryButton,
                      child: Container(
                        width: controlSize,
                        height: controlSize,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          color: colors.onPrimary,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
