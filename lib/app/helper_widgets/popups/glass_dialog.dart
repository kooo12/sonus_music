import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GlassAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color textColor;
  final double blurSigma;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? contentPadding;

  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.backgroundColor = const Color(0x14FFFFFF), // translucent
    this.textColor = Colors.white,
    this.blurSigma = 10,
    this.borderRadius = 20,
    this.borderColor = const Color(0x30FFFFFF),
    this.borderWidth = 1,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AlertDialog(
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          contentPadding: contentPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: borderColor, width: borderWidth),
          ),
          title: _wrapTextColor(title),
          content: _wrapTextColor(content),
          actions: _colorizeActions(actions),
        ),
      ),
    );
  }

  Widget? _wrapTextColor(Widget? child) {
    if (child == null) return null;
    return DefaultTextStyle.merge(
        style: TextStyle(color: textColor), child: child);
  }

  List<Widget>? _colorizeActions(List<Widget>? children) {
    if (children == null) return null;
    return children
        .map((w) => DefaultTextStyle.merge(
            style: TextStyle(color: textColor), child: w))
        .toList();
  }
}
