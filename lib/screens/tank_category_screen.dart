import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/tank.dart';
import '../models/vessel.dart';
import '../state/alert_thresholds.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import '../widgets/tank_status_chip.dart';
import 'tank_calculator_screen.dart';

class TankCategoryScreen extends StatelessWidget {
  final Vessel vessel;
  final TankCategory category;
  final String title;

  const TankCategoryScreen({
    super.key,
    required this.vessel,
    required this.category,
    required this.title,
  });

  Color _categoryColor() {
    switch (category) {
      case TankCategory.fuelOil:
        return AppColors.amber400;
      case TankCategory.brineMud:
        return AppColors.navy500;
      case TankCategory.lubeHydraulic:
        return AppColors.teal500;
      case TankCategory.other:
        return AppColors.statusPort;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanks = vessel.tanksOf(category);
    final color = _categoryColor();
    final data = context.watch<TankDataProvider>();

    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [AiFillAction(onPressed: () => _extractFromFile(context, t))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: tanks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tank = tanks[index];
          final percent = data.percentFor(vessel.id, tank);
          final currentM3 = data.currentLevel(vessel.id, tank.id);
          final status = data.statusFor(vessel.id, tank);

          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TankCalculatorScreen(
                      vesselId: vessel.id, tank: tank, accent: color),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tank.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (status != TankLevelStatus.normal &&
                                  status != TankLevelStatus.noData) ...[
                                const SizedBox(width: 8),
                                TankStatusChip(status: status),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentM3.toStringAsFixed(0)} / ${tank.capacityM3.toStringAsFixed(0)} m³',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(percent * 100).round()}%',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: color),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.35)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// AI-assisted entry: reads a sounding/ROB sheet and reviews each row in a
  /// sheet where the user confirms which tank the reading belongs to (the
  /// AI's tank-name guess only pre-selects the dropdown) and can edit the
  /// level before anything is saved.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'tank_reading');
    if (outcome == null) return;
    final items = outcome.result.items ?? [];
    for (var i = 0; i < items.length; i++) {
      if (!context.mounted) return;
      await _showReviewReadingSheet(
        context,
        t,
        prefill: items[i],
        progressLabel: items.length > 1 ? '(${i + 1}/${items.length})' : null,
      );
    }
  }

  /// Best-effort match of the AI's free-text tank name against this vessel's
  /// tanks — sounding sheets abbreviate freely ("FO Stbd 2" vs "Fuel Oil
  /// Starboard No.2"), so the match only pre-selects and never auto-saves.
  Tank? _matchTank(String name) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final n = norm(name);
    if (n.isEmpty) return null;
    for (final tank in vessel.tanks) {
      final tn = norm(tank.name);
      if (tn == n || tn.contains(n) || n.contains(tn)) return tank;
    }
    return null;
  }

  Future<void> _showReviewReadingSheet(
    BuildContext context,
    AppLocalizations t, {
    required Map<String, dynamic> prefill,
    String? progressLabel,
  }) {
    final aiTankName = aiStr(prefill, 'tankName');
    Tank? tank = _matchTank(aiTankName);
    final levelController =
        TextEditingController(text: aiNumStr(prefill, 'levelM3', ''));
    final tempController =
        TextEditingController(text: aiNumStr(prefill, 'temperatureC', ''));

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        progressLabel == null
                            ? t.updateLevel
                            : '${t.updateLevel} $progressLabel',
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    if (aiTankName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(aiTankName,
                          style: Theme.of(sheetContext).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Tank>(
                      initialValue: tank,
                      decoration: InputDecoration(labelText: t.selectTank),
                      items: vessel.tanks
                          .map((tk) => DropdownMenuItem(
                              value: tk,
                              child: Text(tk.name,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => tank = v),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: levelController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(labelText: t.newReading),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: tempController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          InputDecoration(labelText: t.temperatureLabel),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final level =
                              double.tryParse(levelController.text.trim());
                          final selected = tank;
                          if (selected == null || level == null) return;
                          // AI-extracted values aren't guaranteed sane (OCR
                          // misreads, garbled units) — clamp to the tank's
                          // physical range the same way manual entry does.
                          final clamped =
                              level.clamp(0, selected.capacityM3).toDouble();
                          context.read<TankDataProvider>().addReading(
                                vessel.id,
                                selected.id,
                                clamped,
                                temperatureC: double.tryParse(
                                    tempController.text.trim()),
                              );
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(t.saveReading),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
