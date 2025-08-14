import 'dart:ui';
import 'package:flutter/material.dart';
import 'glassmorphic_container.dart';

Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          // Usamos um SingleChildScrollView para evitar que o conteúdo corte
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassmorphicContainer(
                borderRadius: 16,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}
