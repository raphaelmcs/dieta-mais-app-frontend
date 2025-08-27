// lib/widgets/glass_dialog.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'glassmorphic_container.dart';

/// Dialog com blur real do conteúdo por trás + overlay escuro + container glass.
/// Mesma assinatura pública da sua versão anterior.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent, // importante: deixa transparente para o blur funcionar
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          // 1) BLUR do que está por trás
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: const SizedBox.expand(),
            ),
          ),
          // 2) OVERLAY escuro (controlado por você, não pelo barrier)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          // 3) CONTEÚDO glass dentro de Material para suportar InkWell/ripple
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Material(
                  type: MaterialType.transparency,
                  child: GlassmorphicContainer(
                    borderRadius: 16,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// BottomSheet com blur real + overlay + container glass.
/// Use no lugar de showModalBottomSheet quando quiser efeito glass.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (ctx) {
      return Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                type: MaterialType.transparency,
                child: GlassmorphicContainer(
                  borderRadius: 20,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Month Picker custom no estilo glass (substitui pacotes externos).
/// Inclui Material ao redor dos itens clicáveis para suportar InkWell/ripple.
Future<DateTime?> showGlassMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  Locale? locale,
}) async {
  DateTime viewing = DateTime(initialDate.year, initialDate.month);
  DateTime? selected;

  return showGlassDialog<DateTime?>(
    context: context,
    child: StatefulBuilder(
      builder: (ctx, setState) {
        final theme = Theme.of(ctx);
        final months = List.generate(12, (i) => DateTime(viewing.year, i + 1));

        bool canPrev = DateTime(viewing.year - 1, 12).isAfter(firstDate) ||
            viewing.year - 1 == firstDate.year;
        bool canNext = DateTime(viewing.year + 1, 1).isBefore(lastDate) ||
            viewing.year + 1 == lastDate.year;

        String monthLabel(int m) {
          const pt = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
          const en = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          if ((locale?.languageCode.toLowerCase() ?? 'pt') == 'pt') return pt[m - 1];
          return en[m - 1];
        }

        bool sameYM(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

        bool enabled(DateTime m) =>
            (m.isAfter(firstDate) || sameYM(m, firstDate)) &&
            (m.isBefore(lastDate)  || sameYM(m, lastDate));

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header com navegação de ano
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: canPrev
                        ? () => setState(() => viewing = DateTime(viewing.year - 1, viewing.month))
                        : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${viewing.year}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: canNext
                        ? () => setState(() => viewing = DateTime(viewing.year + 1, viewing.month))
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Grid com 12 meses
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (ctx, i) {
                  final m = months[i];
                  final isEnabled = enabled(m);
                  final isSelected = selected != null && sameYM(selected!, m);

                  return Opacity(
                    opacity: isEnabled ? 1 : 0.35,
                    child: Material( // garante Material para o InkWell/ripple
                      type: MaterialType.transparency,
                      clipBehavior: Clip.antiAlias, // ripple respeita o radius
                      child: InkWell(
                        onTap: isEnabled ? () => setState(() => selected = m) : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.25)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.18),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthLabel(i + 1),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selected == null ? null : () => Navigator.of(context).pop(selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text('Selecionar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
