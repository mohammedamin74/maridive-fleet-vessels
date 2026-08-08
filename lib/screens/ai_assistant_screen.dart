import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/assistant_service.dart';
import '../services/briefing_service.dart';
import '../services/fleet_ai_service.dart';
import '../services/fleet_intel.dart';
import '../state/action_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Session-only chat with two modes. **Help** (Request 5) answers how-to
/// questions and sends only the user's typed text. **Fleet** answers
/// questions about the fleet from a minimal structured snapshot of records
/// this device already read under RLS — health scores, risk severities and
/// short subjects, never crew PII, costs or attachments.
///
/// Either way history lives only in this screen's state and is never
/// persisted, and every fleet answer is labelled as AI output for review.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _sending = false;
  String? _errorCode;

  /// Fleet mode sends the structured snapshot; help mode sends nothing but
  /// the conversation. Switching clears history so the two never mix.
  bool _fleetMode = false;

  void _setMode(bool fleet) {
    if (_fleetMode == fleet) return;
    setState(() {
      _fleetMode = fleet;
      _messages.clear();
      _errorCode = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    // Built before the await so the snapshot matches what the user sees.
    final fleetContext = _fleetMode
        ? BriefingService.aiContext(
            intel: FleetIntel.build(context),
            openActions: context.read<ActionProvider>().open,
          )
        : null;
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _sending = true;
      _errorCode = null;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      final reply = fleetContext == null
          ? await AssistantService.send(_messages)
          : await FleetAiService.ask(
              history: _messages, context: fleetContext);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
      });
    } on AssistantException catch (e) {
      if (!mounted) return;
      setState(() => _errorCode = e.code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorCode = 'unexpected');
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  String _errorMessage(AppLocalizations t, String code) {
    switch (code) {
      case 'not_configured':
        return t.aiUnavailable;
      case 'rate_limited':
        return t.aiBusy;
      default:
        return t.aiError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.aiAssistant)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: Text(t.aiModeHelp)),
                ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.radar, size: 16),
                    label: Text(t.aiModeFleet)),
              ],
              selected: {_fleetMode},
              onSelectionChanged: (s) => _setMode(s.first),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fleetMode ? t.aiFleetDisclaimer : t.aiDisclaimer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                _Bubble(
                    text: _fleetMode ? t.aiFleetGreeting : t.aiGreeting,
                    isUser: false),
                for (final m in _messages)
                  _Bubble(
                    text: m.content,
                    isUser: m.role == 'user',
                    // Fleet answers are advisory: label them so a
                    // recommendation is never mistaken for a decision.
                    aiLabel: _fleetMode && m.role == 'assistant'
                        ? t.aiRecommendationLabel
                        : null,
                  ),
                if (_sending)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (_errorCode != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _errorMessage(t, _errorCode!),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.statusMaintenance),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(hintText: t.aiInputHint),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      child: const Icon(Icons.send, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;

  /// Shown above the text when the answer is AI-generated advice about real
  /// fleet data, so it reads as a recommendation needing review.
  final String? aiLabel;

  const _Bubble({required this.text, required this.isUser, this.aiLabel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isUser
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? scheme.primary
                : scheme.brightness == Brightness.dark
                    ? AppColors.navy800
                    : AppColors.slate100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (aiLabel != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 12, color: AppColors.amber400),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        aiLabel!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                                color: AppColors.amber400,
                                fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Text(
                text,
                style: TextStyle(
                  color: isUser
                      ? (scheme.brightness == Brightness.dark
                          ? AppColors.navy900
                          : Colors.white)
                      : scheme.onSurface,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
