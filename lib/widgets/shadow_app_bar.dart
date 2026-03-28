import 'package:flutter/material.dart';

class ShadowAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget child;

  const ShadowAppBar({required this.child, super.key});

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
