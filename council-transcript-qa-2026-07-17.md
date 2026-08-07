# LLM Council Transcript — QA Audit of Existing Modules — 2026-07-17

## Original question
"Test the existing app and recommend anything required or amended in existing modules — without adding any additional module. Only testing the existing."

## Framed question
Audit and test the existing Maridive Fleet Vessels app (source: /Applications/maridive_fleet_vessels) and recommend required fixes or amendments to EXISTING modules only — no new modules. 16 modules: dashboard+alerts, tanks (readings/history/alarms), defects, requisitions, port calls, certifications (+30-day alarm), urgent notifications, daily tasks, port arrival requirements, crew lists, handover reports, logbook, PDF/unified export, file viewer, AI assistant/extraction, analytics. Bilingual EN/AR RTL, offline-first Hive + Supabase, one developer, crews to use it daily.

Method note: unlike a pure opinion council, each advisor had read access to the actual source tree (and the Executor ran `flutter test` / `flutter analyze` and pattern greps), so findings cite real files and lines.

Anonymization mapping for peer review: A = Executor, B = Outsider, C = Contrarian, D = Expansionist, E = First Principles.

---

## Advisor responses

### The Contrarian (Response C) — all confirmed in source
1. **"Offline-first" is false — offline writes are silently lost.** Every provider does an optimistic in-memory update then `await store.put(...)` with no catch, no queue, no local persistence (lib/state/tank_data_provider.dart:128-130; main.dart confirms Hive holds only settings). Screens fire-and-forget (defect_list_screen.dart:427 calls addDefect unawaited). At sea with no link: the defect/reading appears on screen, the put throws unhandled, and the record vanishes on restart — or sooner, since `_loadAll` replaces the whole cache on every tokenRefreshed.
2. **fetchAll() is unordered and unpaginated** (lib/services/cloud_store.dart:18). PostgREST caps responses at 1000 rows by default. The readings table grows daily across 5 vessels; once past the cap, an arbitrary 1000 rows load and "current tank level = newest cached reading" becomes silently wrong — stale levels and false alarms.
3. **Last-write-wins lost updates.** `put` upserts the entire data blob with no version check, and caches refresh only on login/token events — no realtime subscription anywhere. Two officers editing the same defect/requisition clobber each other's fields invisibly.
4. **Requisition numbers collide.** seq = cache.where(vesselId).length + 1 (tank_data_provider.dart:371-374): delete one requisition, or add from two machines, and you get duplicate REQ-xxx-0007 procurement documents. Record IDs (microsecondsSinceEpoch) can also collide across devices.
5. **Attachment upload fallback re-inlines base64 into jsonb** on any error (attachment_store.dart:36-38) — a multi-MB photo taken offline lands inside the record row, which then must sync through the same failing put.
6. **All failures masquerade as wrong password.** login's `catch (_) => 'invalidCredentials'` (auth_provider.dart:72-74) tells an offline mariner their password is wrong. Plus 26 `catch (_) {}` blocks fleet-wide hide every sync failure.
Fix order: 1→2→3 before anyone trusts this daily.

### The First Principles Thinker (Response E) — can a mariner trust the numbers?
1. **The sounding table is fiction** (lib/models/tank.dart:18-32). soundingTable() invents a linear 250cm profile from capacity ("good enough to demo," says the comment). Real tank geometry is nonlinear; a crew converting a sounding to m³ gets a fabricated number presented as authoritative. Amend: label as uncalibrated estimate, or load real calibration data per tank.
2. **"Offline-first Hive" is false — data loss risk.** Hive stores only locale/theme. addReading optimistically appends to an in-memory cache, then awaits Supabase with no rollback, retry, or local queue; _loadAll swallows all errors. Offline, a saved reading displays, then vanishes on restart.
3. **No-data tanks counted as 0% in fleet averages** (tank_data_provider.dart:133-139) dragging the fleet fuel KPI toward zero — even though alert_thresholds.dart explicitly refuses to conflate no-reading with empty. Amend: average only tanks with readings.
4. **reminderStatus has no "expired" state** (models/vessel_certificate.dart:35-40). A certificate expired 6 months ago is the same red as one 29 days out; inDays truncation also makes day-30/31 boundaries off-by-one. Amend: add expired tier, use date-only math.
5. **Requisition numbers collide** (seq = cached count + 1).
6. **Pump calculator computes from 0 when no reading exists** and clamps negative results to 0, masking impossible operations (tank_calculator_screen.dart:98, 47-67).
7. **Tests cover the wrong risk.** All 11 are serialization round-trips; zero coverage of threshold boundaries, percent/average math, sounding tables, or sequence generation — precisely the numbers crews act on.

### The Expansionist (Response D) — small-effort/high-value amendments (all verified in source)
1. **Unified export covers 7 of ~13 data modules** (export_report_screen.dart) — certifications, maintenance, handover, logbook, urgent notifications absent, yet the ReportSection abstraction and provider getters already exist. Inspectors ask for the cert-expiry table. Biggest value-per-line in the app.
2. **Crew list is blind to certificates** — crew_list_screen.dart has zero references to CertificationProvider though CrewCertificate.reminderStatus exists. One status dot per crew tile plus tap-through.
3. **Defect → requisition one-tap.** Defects capture requiredSpareParts; the requisition add-sheet already accepts a prefill map. ~15 lines closes the spares loop.
4. **Requisition money captured, never totaled.** unitPrice and quantity on every record; analytics shows only counts. Add outstanding-order-value stat + line totals.
5. **Overdue delivery invisible.** requiredDeliveryDate stored and printed, but a late requisition renders identically. One conditional red chip.
6. **Defect aging.** reportedAt exists; open defects show no "N days open" chip or age-sort.
7. **Overdue tasks missing from fleet dashboard.** DailyTasksProvider.overdueCountFor exists but is consumed only in vessel detail.

### The Outsider (Response B) — ranked by daily friction
1. **Every delete is instant, silent, unrecoverable — 12+ screens, zero confirmations.** The only AlertDialog in the codebase is the AI-review dialog. Trash icons sit next to routine actions (daily_task_detail_screen.dart:26-32, port_call_detail_screen.dart:28-31); no undo SnackBar anywhere.
2. **Save buttons silently do nothing on invalid input.** Twelve screens share `if (title.isEmpty) return;` — a crew member taps Save, nothing happens, no message.
3. **Typed text quietly lost.** Checklist comments commit only via onSubmitted and the controller is rebuilt from stored state on every rebuild — ticking a checkbox wipes what you just typed. Same trap for defect "action taken".
4. **No search or filter on any list, anywhere** (0 matches across 27 screens). Requisitions and certifications will accumulate for months.
5. **Sibling-module drift:** defects/requisitions open bottom sheets while tasks/port calls push screens; requisitions editable, defects not; defects get PDF export, requisitions don't.
6. **Locale leaks:** handover drafts hardcode DateFormat('yyyy-MM-dd') and English enum .name values; requisitions hardcode 'pcs'.
All fixable inside existing screens: shared confirm-delete helper, inline validation errors, onChanged persistence, a search field per list header.

### The Executor (Response A) — executed, not just read
Ran flutter test (11/11 pass — all pure model toMap/fromMap round-trips, zero widget/provider/service coverage), flutter analyze (clean), pub outdated (19 held back, none blocking), greps: 26 `catch (_)` silent catches; 31 DateTime.now() in models/state; 35 hardcoded Text('...') strings in screens; 0 force-unwraps; 0 TODOs.
Headline: "offline-first Hive" is false — Hive stores only a settings box. Fix this week: (1) wrap every CloudStore.put/remove call site in try/catch, persist to a Hive pending-sync queue, flush on reconnect — verify by airplane-mode test (add reading, kill app, relaunch, reconnect, appears in Supabase); (2) surface a "cached/offline" banner instead of silently showing an empty-but-healthy fleet. Next: (3) clock-injected boundary tests for cert expiry and task overdue math; (4) migrate the 35 hardcoded strings to ARB and re-verify in Arabic.

---

## Peer reviews

### The Contrarian's review
1. Strongest: **C** — the only response finding failures that survive contact with production at scale: 1000-row cap silently corrupting tank levels, last-write-wins between officers, REQ collisions. Hardest to retrofit later — concurrency and pagination, not string extraction.
2. Biggest blind spot: **D** — polish on a data layer that loses writes, collides IDs, fabricates soundings. An order-value stat computed from a truncated, unordered cache "extends the lie with more confident-looking numbers."
3. All missed: auth/security and multi-vessel data isolation — RLS policies, whether one vessel's crew can clobber another's records, session expiry offshore, role separation. Also: no migration/versioning for the jsonb blobs; Arabic RTL layout never actually tested.

### The First Principles Thinker's review
1. Strongest: **C** — works at the level of guarantees: durability, uniqueness, consistency, completeness, each with mechanism and file:line. E asks the single deepest question (fabricated physical data), but C composes into a coherent diagnosis of the persistence layer.
2. Biggest blind spot: **D** — optimizes the roof while the foundation is condemned.
3. All missed: **the shared root cause** — nearly every C-finding traces to one primitive: a generic CloudStore that upserts entire jsonb blobs. Fix the primitive once, not six symptoms. And the authority model: no roles/RLS; maritime logs are quasi-legal records requiring append-only audit trails — some deletes shouldn't exist at all.

### The Expansionist's review
1. Strongest: **C** — mechanistic, source-confirmed, explains *how* data goes wrong.
2. Biggest blind spot: **D** (its own lens) — genuinely high-leverage amendments, but built on sand: would export the fabricated sounding table, total prices atop colliding REQ numbers, surface cert statuses lacking an expired tier. Polish before integrity amplifies wrong numbers to inspectors — the worst audience.
3. All missed: authorization and audit trail — who may do what; change history as inspectable evidence; whole-blob upsert erases it. And nobody ran the app in Arabic — RTL mirroring, Arabic digits, bidi in exports untested.

### The Outsider's review
1. Strongest: **B** — the only response that watched a human use the app; silent deletes, no-op saves, evaporating text hit crews today with cheap fixes. (C graver long-term.)
2. Biggest blind spot: **D** — same foundation critique.
3. All missed: **nobody ran the app** — every finding is static reading plus 11 serialization tests; no airplane-mode session, no two-device test, no Arabic walkthrough. And no roles or audit trail: any logged-in crew member can silently, permanently delete regulatory records — a compliance exposure, not just UX.

### The Executor's review
1. Strongest: **C** — the bugs a crew can't detect and a developer can't fix later; they must lead any Monday-morning plan.
2. Biggest blind spot: **D** — "sequenced dead last, not first."
3. All missed: authorization and recoverability — RLS, role separation, backups; one mis-tap or one hostile account destroys fleet records permanently. Arabic runtime rendering unverified.
Priority: **C → B(1-3) → A's sync queue → E's labeling → D.**

---

## Chairman's verdict

### Where the Council Agrees
1. **The headline defect: "offline-first" is not real.** Four advisors independently confirmed it (the Expansionist wasn't looking). Hive persists only settings; every module's writes go straight to Supabase with no retry queue, wrapped in silent catches (26 of them). A reading or defect entered offshore appears on screen, then vanishes on restart. This single defect undermines the app's core promise for vessels with intermittent VSAT.
2. **The numbers can't yet be fully trusted:** linear-fiction sounding tables presented as authoritative; fleet fuel average counting unread tanks as 0%; certificate status without an "expired" tier and with day-boundary off-by-one; pump calculator computing from zero; REQ numbers that can duplicate.
3. **Daily-use safety gaps in every list screen:** instant unrecoverable deletes with no confirmation anywhere, save buttons that silently no-op on invalid input, typed text lost on rebuild, and no search on any list.
4. **The test suite tests the wrong things** — 11 serialization round-trips, zero coverage of the alarm/expiry/average math crews act on.

### Where the Council Clashes
- **What to fix first:** the Outsider argues user-facing safety (deletes/saves/search) harms crews *tomorrow*; the Contrarian and three reviewers argue the invisible data-layer bugs are graver because crews can't detect them and they get harder to fix as data grows. The Executor's reviewer resolved the order: data layer first, then the three worst UX traps, then the rest.
- **The Expansionist's amendments** (export coverage, cert dots on crew list, defect→requisition prefill, order totals, overdue chips) were unanimously judged *right ideas, wrong time* — all five reviewers flagged surfacing more numbers before the numbers are trustworthy. They stay on the list, sequenced last.

### Blind Spots the Council Caught
- **Access control and audit trail (all 5 reviewers):** nobody checked Supabase RLS policies, role separation, or change history. Any authenticated user can silently and permanently delete any vessel's records — for quasi-legal maritime documents, that's a compliance exposure confirmation dialogs alone don't fix.
- **The root cause is one primitive:** most data-layer findings trace to CloudStore's whole-blob jsonb upsert. Fix the primitive (ordered/paginated fetch, error handling, pending queue, updated-at conflict guard) once, and six symptoms collapse into one repair.
- **Nobody actually ran the app** — no airplane-mode session, no two-device conflict test, no Arabic RTL runtime walkthrough. Static analysis found much; runtime testing remains undone.

### The Recommendation
Run a **repair sprint on existing modules** in this order, shipping each phase behind the usual analyze/test/build gate:
1. **Data durability (CloudStore + providers):** try/catch on every put/remove; Hive pending-sync queue flushed on reconnect; ordered + paginated fetch; per-record updated-at conflict guard; honest offline/auth error states replacing the 26 silent catches.
2. **Crew safety UX (shared helpers, all list screens):** confirm-delete dialog + undo SnackBar, inline validation messages, onChanged draft persistence, search field on every list.
3. **Number honesty:** sounding table labeled as estimate (or real calibration data), fleet averages skip unread tanks, "expired" certificate tier with date-only math, calculator guard when no reading exists.
4. **Tests + localization:** clock-injected boundary tests for expiry/overdue/threshold math; migrate the 35 hardcoded strings; full Arabic runtime pass.
Then — and only then — the Expansionist's seven polish amendments. In parallel, review Supabase RLS policies and add a change-history column to the CloudStore schema.

### The One Thing to Do First
Make one offline write survive: wrap CloudStore.put in try/catch with a Hive pending-sync queue, then run the airplane-mode test — add a tank reading offline, kill the app, relaunch (reading still there), reconnect (reading in Supabase). Everything else builds on that guarantee.
