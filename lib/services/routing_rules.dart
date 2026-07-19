/// Decides which module `kind` (a key in the `extract` edge function's KINDS
/// registry — see supabase/functions/extract/index.ts) a batch file should be
/// extracted against, when the user hasn't already told it explicitly.
///
/// Rules are data, not code — adding a 14th module kind to this pipeline is
/// one new [RoutingRule] entry (plus its existing KINDS registry entry),
/// mirroring the edge function's own "schema registry is the only thing that
/// grows" design.
class RoutingContext {
  final String filename;
  final String detectedExt;
  final String? screenHint;
  final String? userAnnotation;

  const RoutingContext({
    required this.filename,
    required this.detectedExt,
    this.screenHint,
    this.userAnnotation,
  });
}

class RoutingDecision {
  final String? kind; // null when unclassified
  final double confidence;
  final String ruleId;

  const RoutingDecision._(this.kind, this.confidence, this.ruleId);

  factory RoutingDecision.confident(String kind,
          {required double confidence, required String ruleId}) =>
      RoutingDecision._(kind, confidence, ruleId);

  factory RoutingDecision.unclassified() =>
      const RoutingDecision._(null, 0, 'unclassified');

  bool get isClassified => kind != null;
}

class RoutingRule {
  final String id;
  final int priority; // lower = evaluated first
  final String targetKind;
  final double confidence;
  final bool Function(RoutingContext ctx) matches;

  const RoutingRule({
    required this.id,
    required this.priority,
    required this.targetKind,
    required this.confidence,
    required this.matches,
  });
}

const double _routingThreshold = 0.6;

// Filenames commonly use '_'/'-'/'.' as word separators, but '_' is itself a
// regex word character — "CoC_Master.pdf" has no \b boundary between "C" and
// "_", so a plain \bcoc\b silently fails to match real filenames exactly
// like this. Normalize separators to spaces first so \b behaves as intended.
String _normalizedName(RoutingContext ctx) =>
    ctx.filename.replaceAll(RegExp(r'[_\-.]'), ' ');

bool _nameHas(RoutingContext ctx, RegExp pattern) =>
    pattern.hasMatch(_normalizedName(ctx));

/// Ordered by priority: certificate-type-specific rules run before the
/// generic "certificate" fallback so a CoC/STCW/medical filename never gets
/// misrouted to the vessel-certificate module.
final List<RoutingRule> defaultRoutingRules = [
  RoutingRule(
    id: 'crew_certificate_keyword',
    priority: 1,
    targetKind: 'crew_certificate',
    confidence: 0.85,
    matches: (ctx) => _nameHas(
        ctx, RegExp(r'\bcoc\b|stcw|medical|crew[\s_-]?cert', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'vessel_certificate_keyword',
    priority: 2,
    targetKind: 'vessel_certificate',
    confidence: 0.8,
    matches: (ctx) => _nameHas(
        ctx,
        RegExp(r'certificate|class\s*society|load[\s_-]?line|safety\s*(con|equip|radio)',
            caseSensitive: false)),
  ),
  RoutingRule(
    id: 'defect_keyword',
    priority: 3,
    targetKind: 'defect',
    confidence: 0.8,
    matches: (ctx) =>
        _nameHas(ctx, RegExp(r'defect|fault|breakdown', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'requisition_keyword',
    priority: 4,
    targetKind: 'requisition',
    confidence: 0.8,
    matches: (ctx) => _nameHas(
        ctx,
        RegExp(r'requisition|quotation|parts?[\s_-]?list|purchase',
            caseSensitive: false)),
  ),
  RoutingRule(
    id: 'tank_reading_keyword',
    priority: 5,
    targetKind: 'tank_reading',
    confidence: 0.75,
    matches: (ctx) =>
        _nameHas(ctx, RegExp(r'sounding|ullage|\brob\b|tank', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'logbook_keyword',
    priority: 6,
    targetKind: 'logbook',
    confidence: 0.8,
    matches: (ctx) =>
        _nameHas(ctx, RegExp(r'logbook|log[\s_-]?book|deck[\s_-]?log', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'maintenance_keyword',
    priority: 7,
    targetKind: 'maintenance',
    confidence: 0.8,
    matches: (ctx) => _nameHas(
        ctx, RegExp(r'maintenance|\bpms\b|work[\s_-]?order', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'port_call_keyword',
    priority: 8,
    targetKind: 'port_call',
    confidence: 0.75,
    matches: (ctx) => _nameHas(
        ctx,
        RegExp(r'port[\s_-]?call|agent|pre[\s_-]?arrival|husbandry',
            caseSensitive: false)),
  ),
  RoutingRule(
    id: 'port_requirement_keyword',
    priority: 9,
    targetKind: 'port_requirement',
    confidence: 0.7,
    matches: (ctx) => _nameHas(
        ctx, RegExp(r'requirement|customs|arrival[\s_-]?doc', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'crew_keyword',
    priority: 10,
    targetKind: 'crew',
    confidence: 0.8,
    matches: (ctx) => _nameHas(
        ctx, RegExp(r'crew[\s_-]?list|sign[\s_-]?on|sign[\s_-]?off', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'daily_task_keyword',
    priority: 11,
    targetKind: 'daily_task',
    confidence: 0.7,
    matches: (ctx) => _nameHas(
        ctx,
        RegExp(r'daily|watch[\s_-]?routine|rounds|checklist', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'urgent_notification_keyword',
    priority: 12,
    targetKind: 'urgent_notification',
    confidence: 0.8,
    matches: (ctx) => _nameHas(
        ctx, RegExp(r'urgent|incident|alert|emergency', caseSensitive: false)),
  ),
  RoutingRule(
    id: 'handover_keyword',
    priority: 13,
    targetKind: 'handover',
    confidence: 0.85,
    matches: (ctx) => _nameHas(
        ctx, RegExp(r'handover|hand[\s_-]?over|turnover', caseSensitive: false)),
  ),
];

/// User annotation always wins; a screen hint (batch launched from a
/// specific module screen) is next; otherwise the highest-priority matching
/// filename rule; otherwise unclassified — never a silent low-confidence
/// guess on a safety-relevant record.
RoutingDecision route(RoutingContext ctx, [List<RoutingRule>? rules]) {
  if (ctx.userAnnotation != null && ctx.userAnnotation!.isNotEmpty) {
    return RoutingDecision.confident(ctx.userAnnotation!,
        confidence: 1.0, ruleId: 'user_override');
  }
  if (ctx.screenHint != null && ctx.screenHint!.isNotEmpty) {
    return RoutingDecision.confident(ctx.screenHint!,
        confidence: 0.95, ruleId: 'screen_hint');
  }
  final sorted = [...(rules ?? defaultRoutingRules)]
    ..sort((a, b) => a.priority.compareTo(b.priority));
  for (final rule in sorted) {
    if (rule.confidence >= _routingThreshold && rule.matches(ctx)) {
      return RoutingDecision.confident(rule.targetKind,
          confidence: rule.confidence, ruleId: rule.id);
    }
  }
  return RoutingDecision.unclassified();
}
