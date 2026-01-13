import 'package:flutter/material.dart';

class CustomTableRow {
  final List<Widget> children;
  final bool isHeader;

  CustomTableRow({
    required this.children,
    this.isHeader = false,
  });
}
