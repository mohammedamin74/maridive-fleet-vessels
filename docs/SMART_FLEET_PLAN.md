# Maridive Smart Fleet — Technical Implementation Plan

Source spec: `Maridive_Smart_Fleet_Claude_Development_Design.md` (Technical Superintendent risk-intelligence platform). This plan maps the spec onto the **actual repository** — everything reuses the existing Provider + CloudStore + SyncQueue + l10n + token architecture. Nothing is rebuilt.

## Ground rules (from spec §18, §26)

- Deterministic first: Phase 1 intelligence is **pure Dart rules**, no AI calls. Every risk carries evidence (source record) and an explanation; nothing is invented.
- AI features (fleet assistant, daily briefing, discrepancy detection) come in Phase 2, server-side only, free models only.
- No regressions: analyze 0 issues, existing tests stay green, EN/AR + light/dark verified per phase.
- Public repo: no business data, no secrets.

## Phase 1 — Intelligence Foundation (this phase)

### New models — `lib/models/fleet_intelligence.dart`, `lib/models/superintendent_action.dart`
- `RiskSeverity` (critical > high > medium > low > info), `RiskCategory` (the 7 health components + dataQuality), `RiskKind` (~16 deterministic rule ids).
- `RiskEvent`: computed, never persisted in Phase 1 — id derived from source record, vesselId, kind, category, severity, subject (real record text), days/count params, sourceType + sourceId (evidence), dueDate.
- `VesselHealth`: overall 0–100 score, band (good ≥80 / attention ≥60 / highRisk ≥40 / critical), 7 component scores, deduction list (points + causing risk) so every score answers "why".
- `SuperintendentAction` (persisted): vessel, source module + record id, priority, title/description/recommendation, assignedTo, dueDate, 6 statuses (open, inProgress, waitingVessel, waitingOffice, completed, cancelled), attachments, createdBy/At, completedAt.

### Risk engine — `lib/services/risk_engine.dart` (pure, unit-tested)
Rules per vessel using `clockNow()`:
- Defects: open critical → CRITICAL; open high → HIGH; open low/medium older than 30 days → MEDIUM; ≥3 same-titled defects → MEDIUM "recurring pattern — review required" (never auto-diagnosed).
- Vessel certificates (spec §13 windows): expired/≤7d → CRITICAL, ≤30d → HIGH, ≤60d → MEDIUM, ≤90d → LOW. Crew certificates: same windows under the Crew component.
- Maintenance: past due & not completed → HIGH; due within 7 days → LOW.
- Requisitions: urgent still in approval after 7 days → HIGH; required delivery date passed & not received → MEDIUM.
- Port readiness: each pending port requirement → LOW.
- Operational: unacknowledged urgent notification → HIGH; overdue tracked action → HIGH; overdue daily tasks → MEDIUM (aggregated count).
- Data quality: open critical/high defect with no assigned officer → INFO.

### Health score — `lib/services/vessel_health_service.dart` (pure, unit-tested)
- Component = 100 − severity penalties (critical 45, high 25, medium 12, low 5, info 0), floored at 0.
- Overall = weighted: defects 20, maintenance 20, certificates 15, operational 15, requisitions 10, crew 10, port readiness 10 (spec §5 weights, constants in one place).
- Any CRITICAL risk caps the overall at 55 — a critical condition can never hide inside a "good" average.
- `FleetIntel` helper computes risks + health for all vessels from the existing providers (watch-based, cheap at fleet size 5).

### Action Center — `lib/state/action_provider.dart` + `superintendent_actions` table
- CloudStore pattern identical to `cash_meeting_provider.dart` (offline-safe via SyncQueue). Table added to `schema.sql` `module_tables`.
- Views: My Actions (assignedTo/createdBy matches current user), Fleet, Overdue, Critical.

### UI
- `HomeShell` grows to 6 tabs: **Fleet · Risk · Actions · Analytics · Assistant · Settings**.
- `lib/screens/risk_screen.dart`: severity summary, vessel filter, grouped risk list with evidence + recommendation + one-tap "Create action" (prefills a SuperintendentAction from the risk).
- `lib/screens/actions_screen.dart`: 4 views, status workflow, add/edit sheet, confirm-delete.
- Dashboard Command Center panel: fleet health counts (healthy/attention/high-risk/critical), vessel ranking by score with band colors, top priority-attention items; tapping a vessel opens the "why this score" breakdown (component scores + deductions).

### Acceptance (spec §24/§25)
analyze 0 → all tests green (existing + new engine/score tests) → macOS release build + reinstall → EN/AR, light/dark visual check → push (web auto-deploys).

## Phase 2 — Intelligence (shipped, except document discrepancy detection)

- **Daily Briefing** (`briefing_service.dart` + `daily_briefing_screen.dart`): critical / high priority / upcoming / open actions / verified-quiet sections, built deterministically from the same FleetIntel snapshot so it works offline. Copy-to-clipboard management summary and PDF export (`ReportService.exportBriefingPdf`).
- **`fleet-ai` edge function**: answers fleet questions from a minimal structured snapshot the signed-in client sends. The function has **no database access and no service-role key** — the client already reads under RLS, so the model can never see more than the user can. The snapshot carries health scores plus risk severity/category/rule and truncated subjects; never crew PII, costs, suppliers, record ids or attachments (pinned by `test/briefing_test.dart`). JWT-verified, per-user throttle, free-model fallback chain.
- **Fleet mode in the AI Assistant**: Help ↔ My fleet toggle; switching clears history so the two contexts never mix. Every fleet answer is labelled "AI recommendation — human review required", in-app and in the PDF. Model Markdown is flattened to plain text for display and print.
- AI risk explanations and recurring-defect detection are covered by Phase 1's deterministic rules (a repeated defect is flagged as a pattern for review, never a diagnosed cause).
- **Deferred to Phase 2b**: document discrepancy detection in the ingestion pipeline — compare an AI-extracted certificate against the existing record and surface the difference for review, never overwriting.

`ai_briefings` persistence is deliberately not implemented yet: a briefing is cheap to recompute and always current, so storing it would only add stale copies. It becomes worthwhile in Phase 3, when trends need historical snapshots.

## Phase 3 — Management
Executive dashboard with trends (needs Phase 1 snapshots — start persisting `vessel_health_scores` snapshots at the start of Phase 3), fleet ranking report, extended unified report, action KPIs.

## Phase 4 — Advanced
Predictive maintenance & reliability analytics — only once enough history exists (spec §12 explicitly defers this).

## Deliberate Phase 1 simplifications
- Risks/health are computed on-device, not persisted (`risk_events`/`vessel_health_scores` tables deferred until trends need them in Phase 3) — avoids sync complexity with zero user-visible loss now.
- Roles stay admin/non-admin (spec §20 full role matrix deferred; RLS unchanged).
- Comments on actions start as a notes field; threaded comments come with Phase 2.
