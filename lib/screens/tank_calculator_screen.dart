import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/tank.dart';
import '../state/alert_thresholds.dart';
import '../state/tank_data_provider.dart';
import '../widgets/tank_level_bar.dart';
import '../widgets/tank_status_chip.dart';
import 'sounding_table_screen.dart';
import 'tank_history_screen.dart';

class TankCalculatorScreen extends StatefulWidget {
  final String vesselId;
  final Tank tank;
  final Color accent;

  const TankCalculatorScreen({
    super.key,
    required this.vesselId,
    required this.tank,
    required this.accent,
  });

  @override
  State<TankCalculatorScreen> createState() => _TankCalculatorScreenState();
}

class _TankCalculatorScreenState extends State<TankCalculatorScreen> {
  final _pumpQtyController = TextEditingController();
  final _stopLevelController = TextEditingController();
  final _newReadingController = TextEditingController();

  double? _remainingAfterPumping;
  double? _quantityToReachLevel;

  @override
  void dispose() {
    _pumpQtyController.dispose();
    _stopLevelController.dispose();
    _newReadingController.dispose();
    super.dispose();
  }

  void _onPumpQtyChanged(String value, double currentM3) {
    final qty = double.tryParse(value);
    setState(() {
      _remainingAfterPumping =
          qty == null ? null : (currentM3 - qty).clamp(0, widget.tank.capacityM3);
    });
  }

  void _onStopLevelChanged(String value, double currentM3) {
    final level = double.tryParse(value);
    setState(() {
      if (level == null) {
        _quantityToReachLevel = null;
        return;
      }
      final targetVolume = widget.tank.capacityM3 * (level / 100);
      _quantityToReachLevel = (currentM3 - targetVolume).clamp(0, widget.tank.capacityM3);
    });
  }

  Future<void> _saveReading() async {
    final value = double.tryParse(_newReadingController.text);
    if (value == null) return;
    final clamped = value.clamp(0, widget.tank.capacityM3).toDouble();
    await context.read<TankDataProvider>().addReading(widget.vesselId, widget.tank.id, clamped);
    if (!mounted) return;
    _newReadingController.clear();
    setState(() {});
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tank = widget.tank;
    final accent = widget.accent;
    final data = context.watch<TankDataProvider>();
    final currentM3 = data.currentLevel(widget.vesselId, tank.id);
    final percent = data.percentFor(widget.vesselId, tank);
    final hasReading = data.hasReading(widget.vesselId, tank.id);
    final status = levelStatusFor(hasReading: hasReading, percent: percent);
    final readings = data.readingsFor(widget.vesselId, tank.id);

    return Scaffold(
      appBar: AppBar(title: Text(tank.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  TankLevelBar(percent: percent, color: accent, height: 140),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${(percent * 100).round()}%',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: accent),
                            ),
                            const SizedBox(width: 10),
                            if (status != TankLevelStatus.normal) TankStatusChip(status: status),
                          ],
                        ),
                        Text(t.tankPercent, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        _MetricRow(label: t.currentVolume, value: '${currentM3.toStringAsFixed(1)} m³'),
                        const SizedBox(height: 8),
                        _MetricRow(label: t.capacity, value: '${tank.capacityM3.toStringAsFixed(0)} m³'),
                        const SizedBox(height: 8),
                        Text(
                          readings.isEmpty
                              ? t.noReadingsYet
                              : '${t.lastUpdated}: ${_formatTimestamp(readings.first.timestamp)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(t.updateLevel, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _newReadingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: t.newReading,
                    suffixText: t.cubicMeters,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveReading,
                  style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
                  child: Text(t.saveReading),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TankHistoryScreen(vesselId: widget.vesselId, tank: tank, accent: accent),
              ),
            ),
            icon: const Icon(Icons.history),
            label: Text(t.viewHistory),
          ),
          const SizedBox(height: 24),
          Text(t.pumpCalculator, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(
            controller: _pumpQtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => _onPumpQtyChanged(v, currentM3),
            decoration: InputDecoration(
              labelText: t.quantityToPumpOut,
              suffixText: t.cubicMeters,
            ),
          ),
          if (_remainingAfterPumping != null) ...[
            const SizedBox(height: 10),
            _ResultBanner(
              label: t.remainingAfterPumping,
              value: '${_remainingAfterPumping!.toStringAsFixed(1)} m³',
              color: accent,
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _stopLevelController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => _onStopLevelChanged(v, currentM3),
            decoration: InputDecoration(
              labelText: t.stopPumpingAtLevel,
              suffixText: t.percent,
            ),
          ),
          if (_quantityToReachLevel != null) ...[
            const SizedBox(height: 10),
            _ResultBanner(
              label: t.quantityToPumpOut,
              value: '${_quantityToReachLevel!.toStringAsFixed(1)} m³',
              color: accent,
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SoundingTableScreen(tank: tank)),
            ),
            icon: const Icon(Icons.table_chart_outlined),
            label: Text(t.categorySoundingTables),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(locale).add_Hm().format(dt);
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultBanner({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
