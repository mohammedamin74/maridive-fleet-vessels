import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/tank.dart';
import '../models/tank_reading.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/tank_history_chart.dart';

class TankHistoryScreen extends StatelessWidget {
  final String vesselId;
  final Tank tank;
  final Color accent;

  const TankHistoryScreen({
    super.key,
    required this.vesselId,
    required this.tank,
    required this.accent,
  });

  Future<void> _editReading(BuildContext context, AppLocalizations t,
      TankReading reading, Tank tank) async {
    final levelController =
        TextEditingController(text: reading.levelM3.toString());
    final tempController = TextEditingController(
        text: reading.temperatureC?.toString() ?? '');
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: levelController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: t.currentVolume, suffixText: t.cubicMeters),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: tempController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration:
                  InputDecoration(labelText: t.temperatureLabel, suffixText: '°C'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('delete'),
            child: Text(t.delete,
                style: const TextStyle(color: AppColors.statusMaintenance)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (!context.mounted || action == null) return;
    final data = context.read<TankDataProvider>();
    if (action == 'delete') {
      final ok = await confirmDelete(context,
          itemName: '${reading.levelM3.toStringAsFixed(1)} m³');
      if (ok && context.mounted) data.deleteReading(reading);
      return;
    }
    final level = double.tryParse(levelController.text);
    if (level == null) return;
    final clamped = level.clamp(0, tank.capacityM3).toDouble();
    final temp = double.tryParse(tempController.text);
    await data.updateReading(reading, levelM3: clamped, temperatureC: temp);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final readings = data.readingsFor(vesselId, tank.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text('${t.readingHistory} — ${tank.name}')),
      body: readings.isEmpty
          ? Center(
              child: Text(t.noHistory,
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: readings.length + (readings.length > 1 ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (readings.length > 1 && index == 0) {
                  return TankHistoryChart(
                      readings: readings,
                      color: accent,
                      capacityM3: tank.capacityM3);
                }
                index = readings.length > 1 ? index - 1 : index;
                final reading = readings[index];
                final percent = tank.capacityM3 <= 0
                    ? 0.0
                    : (reading.levelM3 / tank.capacityM3).clamp(0, 1);
                final prev =
                    index + 1 < readings.length ? readings[index + 1] : null;
                final delta =
                    prev == null ? null : reading.levelM3 - prev.levelM3;

                return Card(
                  child: InkWell(
                    onTap: () => _editReading(context, t, reading, tank),
                    child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reading.temperatureC != null
                                    ? '${reading.levelM3.toStringAsFixed(1)} m³ · ${(percent * 100).round()}% · ${reading.temperatureC!.toStringAsFixed(1)}°C'
                                    : '${reading.levelM3.toStringAsFixed(1)} m³ · ${(percent * 100).round()}%',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFmt.format(reading.timestamp),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        if (delta != null && delta != 0)
                          Row(
                            children: [
                              Icon(
                                delta > 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 14,
                                color: delta > 0
                                    ? AppColors.statusActive
                                    : AppColors.statusMaintenance,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                delta.abs().toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: delta > 0
                                      ? AppColors.statusActive
                                      : AppColors.statusMaintenance,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
