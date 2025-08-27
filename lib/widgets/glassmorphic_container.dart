import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  final EdgeInsetsGeometry? margin;     // <- NOVO
  final EdgeInsetsGeometry? padding;    // <- OPCIONAL
  final double blurSigma;               // <- OPCIONAL (para blur real)

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.color = Colors.white,
    this.margin,                        // <- NOVO
    this.padding,                       // <- OPCIONAL
    this.blurSigma = 0,                 // 0 = sem blur; >0 ativa BackdropFilter
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,                   // <- NOVO
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.20),
            color.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          width: 1.5,
          color: color.withOpacity(0.2),
        ),
      ),
      child: child,
    );

    // Se blurSigma > 0, aplica o efeito fosco real
    if (blurSigma > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    return content;
  }
}