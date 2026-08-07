# Maridive Fleet Vessels

A bilingual (English / Arabic) fleet-management app for the Maridive Libya vessel fleet, built with Flutter. It runs today as a macOS desktop app and as a web app (GitHub Pages), with Android/iOS/Windows/Linux targets scaffolded for later.

- **Repo:** https://github.com/mohammedamin74/maridive-fleet-vessels
- **Backend:** Supabase (project "Maridive-Libya Fleet") — Postgres + Auth + Storage + Edge Functions
- **AI:** OpenRouter free-tier models (document extraction + help assistant) and Gemini (profile imagery)

---

## The fleet

| Vessel | Type | Working port |
|---|---|---|
| Maridive 701 | Anchor Handling Tug Supply (AHTS, 71 m) | Tripoli |
| Maridive 704 | Anchor Handling Tug Supply (AHTS, 71 m) | Tripoli |
| Maridive 601 | Platform Supply Vessel (PSV) | Tripoli |
| MRD ZOHR I | — | — |
| MRD ZOHR II | — | — |

Vessel particulars and full tank capacity tables (from each vessel's sounding booklet / capacity plan) are hardcoded in `lib/data/fleet_data.dart`.

---

## App structure

### Navigation

An adaptive shell (`lib/screens/home_shell.dart`) hosts four top-level tabs — **Fleet**, **Analytics**, **Assistant**, **Settings** — shown as a `NavigationRail` on wide windows (≥600 px) and a bottom `NavigationBar` on narrow ones. Tab state is preserved in an `IndexedStack`. All module screens push as full-window routes over the shell. The rail automatically sits on the right in Arabic (RTL).

### Fleet dashboard (`dashboard_screen.dart`)

- Hero header, fleet stat tiles, searchable/filterable vessel grid (responsive: 1–2 columns).
- Alert panels: low-tank alerts, expiring certificates, open defects, urgent notifications banner.
- **Management card** — opens the Cash Meeting Sheet module (fleet-level, not per-vessel).

### Per-vessel modules (vessel detail grid)

| Module | Screen | Highlights |
|---|---|---|
| Tanks | `tank_category_screen.dart`, `tank_calculator_screen.dart`, `sounding_table_screen.dart` | Sounding→volume calculators per tank, manual readings, level bars |
| Tank history | `tank_history_screen.dart` | Hand-rolled history chart, high/low alarms |
| Logbook | `vessel_logbook_screen.dart` | Dated notes with attachments |
| Vessel specs | `vessel_specs_screen.dart` | Particulars, editable, AI-fill |
| Defects | `defect_list_screen.dart` | Status workflow, photos, AI-fill from documents |
| Requisitions | `requisition_list_screen.dart` | Purchase requests, statuses, AI-fill |
| Port calls | `port_call_list_screen.dart`, `port_call_detail_screen.dart` | Port logistics with checklists |
| Port arrival requirements | `port_requirements_screen.dart` | Pre-arrival paperwork tracking |
| Certificates | `certification_screen.dart` | Vessel + crew certificates with expiry alerts |
| Crew | `crew_list_screen.dart` | Current/previous crew lists |
| Urgent notifications | `urgent_notifications_screen.dart` | Alert center with assignable actions |
| Daily tasks | `daily_tasks_list_screen.dart`, `daily_task_detail_screen.dart` | Tasks with photo evidence |
| Maintenance | `maintenance_list_screen.dart` | Maintenance records |
| Handover | `handover_list_screen.dart` | Crew handover reports with PDF export |
| Export report | `export_report_screen.dart`, `report_preview_screen.dart` | Unified per-vessel report, in-app preview, PDF/CSV |
| AI ingestion | `ingestion_batch_screen.dart` | Drop a mixed document; a routing-rules engine splits extracted rows across modules for review |

### Management — Cash Meeting Sheet (fleet-level)

`cash_meeting_screen.dart` + `cash_meeting_report_screen.dart`

A rolling purchase-approval ledger modeled on the office's cash meeting Excel sheet:

- Two tabs: **Not approved** / **Approved**; per-vessel filter chips; per-currency subtotals (EUR/USD/GBP are never summed together).
- Each line: vessel, operation, description, PR number, cost + currency, supplier, PO number, notes, attachments.
- Approve/return toggles stamp or clear the decision date.
- AI-fill: point it at a cash meeting sheet (Excel/PDF/photo) and review extracted lines one by one.
- **Report view**: grouped not-approved/approved sections plus per-status × per-currency totals, downloadable as PDF or CSV.

### Analytics (`analytics_dashboard_screen.dart`)

Fleet-wide charts (hand-rolled bar + donut painters with accessibility semantics): tank levels, defect/requisition counts, certificate expiry outlook. Reachable as a tab or pushed from a vessel with that vessel pre-selected.

### AI Assistant (`ai_assistant_screen.dart`)

Help-only chat ("how do I…" about the app). It never receives fleet data — only the typed conversation. Backed by the `assistant` edge function.

### Settings (`settings_screen.dart`) + User management (`user_management_screen.dart`)

Language (EN/AR), theme, alert thresholds, sign-out. Admins (`is_admin` flag) manage users via the `admin-users` edge function.

---

## Architecture

```
UI (screens/widgets)
  └─ Provider state (lib/state/*_provider.dart, one per module)
       └─ CloudStore (lib/services/cloud_store.dart)
            ├─ Supabase Postgres  (online writes)
            └─ SyncQueue + Hive   (offline queue, flushed on reconnect)
```

- **State:** `provider` ChangeNotifiers, one per module, registered in `main.dart`. Each reloads on auth-state changes.
- **Persistence:** every module maps to one Supabase table with the generic shape `{id text pk, vessel_id text, data jsonb, updated_at timestamptz}` (see `supabase/schema.sql` — the `module_tables` array creates all tables, indexes, and RLS in one loop). RLS: authenticated fleet users have full access.
- **Offline-first:** writes that fail go into `SyncQueue` (Hive) and flush automatically when connectivity/auth returns.
- **Attachments:** private `attachments` Storage bucket via `attachment_store.dart`; universal in-app viewer (`file_viewer.dart`) renders images, PDFs, and spreadsheets-as-tables.
- **Reports:** `report_service.dart` builds unified PDF (with Arabic font fallback) and CSV (UTF-8 BOM) exports; every export also has an in-app preview screen.
- **Design system:** `lib/theme/app_tokens.dart` (spacing/gaps/radii/breakpoints) + a complete Material `TextTheme` and component themes in `app_theme.dart`. Navy/teal maritime palette, light + dark, fully RTL-safe (`EdgeInsetsDirectional` etc.).
- **Localization:** ARB-based (`lib/l10n/app_en.arb`, `app_ar.arb`), including Arabic plural forms; regenerate with `flutter gen-l10n`.

## Supabase backend

Project ref: `forcpesacwaektzyslyh` (free tier).

### Edge functions (`supabase/functions/`)

| Function | Purpose | Notes |
|---|---|---|
| `extract` | AI document extraction (13+ "kinds": defects, requisitions, crew, certificates, cash items, …) | Walks a fallback chain of OpenRouter `:free` text/vision models; Gemini fallback for vision |
| `assistant` | Help-only chat for the AI Assistant tab | Same OpenRouter key; per-user throttle (8 req/min); fallback model chain |
| `admin-users` | User administration for admins | |
| `genimage` | Synthetic fleet profile imagery via Gemini image model | Never used for evidence photos |

All functions have `verify_jwt = true` (`supabase/config.toml`) — they require a signed-in user.

**Secrets** (set via `supabase secrets set`, never committed): `OPENROUTER_API_KEY`, `GEMINI_API_KEY`.

Deploy a function:

```bash
npx --yes supabase functions deploy extract --project-ref forcpesacwaektzyslyh
```

### Operational gotchas

- **Free-tier auto-pause:** the Supabase project pauses after ~1 week of inactivity; the app then hangs at login (the project URL stops resolving in DNS entirely). Fix: dashboard → *Resume project*. Regular daily use prevents it; the Pro plan removes it.
- **Free-model delisting:** OpenRouter removes `:free` models without warning (this once silently broke the assistant). Both `extract` and `assistant` therefore use fallback chains — if AI features degrade, check the live list at `https://openrouter.ai/api/v1/models` and refresh the `MODELS`/`TEXT_MODELS`/`VISION_MODELS` arrays. **Free models only — never paid models.**
- **Public repo:** never commit real business data (suppliers, costs, PO/PR numbers, crew PII) or seed SQL containing it. Data lives only in Supabase.

## Development

Flutter SDK: `~/development/flutter-3.44.6/bin/flutter` (Dart ^3.5.4).

```bash
flutter pub get
flutter gen-l10n          # after editing ARB files
flutter analyze           # must stay at 0 issues
flutter test              # all tests must pass
flutter run -d macos
```

Release build + install (macOS):

```bash
flutter build macos --release
```

then replace the app in `/Applications` with `build/macos/Build/Products/Release/maridive_fleet_vessels.app`.

### Verification loop (used after every change)

analyze (0 issues) → test (all green) → release build → reinstall → visual check of the affected screens in EN and AR, light and dark.

## Deployment

- **Web:** any push to `main` triggers `.github/workflows/deploy-web.yml`, which builds `flutter build web --release --base-href /maridive-fleet-vessels/` and publishes to GitHub Pages (`gh-pages` branch).
- **macOS:** built and installed locally (no notarized distribution yet).

## Key dependencies

`supabase_flutter`, `provider`, `hive`/`hive_flutter`, `pdf` + `printing`, `file_picker`/`file_saver`, `excel`, `intl`, `crypto`, `archive` — plus Flutter's built-in localization. The project philosophy is hand-rolled over new dependencies (charts, breakpoints, and design tokens are all custom).
