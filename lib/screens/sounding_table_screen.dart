import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/tank.dart';
import '../theme/app_colors.dart';

class SoundingTableScreen extends StatelessWidget {
  final Tank tank;
  const SoundingTableScreen({super.key, required this.tank});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final rows = tank.soundingTable();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.soundingTableTitle(tank.name))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: scheme.brightness == Brightness.dark
                    ? AppColors.navy700.withOpacity(0.5)
                    : AppColors.slate100,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(t.levelCm, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Expanded(
                      child: Text(
                        t.volumeM3,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
                  itemBuilder: (context, index) {
                    final row = rows[rows.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: Text('${row.levelCm}')),
                          Expanded(
                            child: Text(
                              row.volumeM3.toStringAsFixed(1),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
