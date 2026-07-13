# Maridive Fleet Vessels — Enhancement Plan

Status: **Proposed** · Author: engineering · Target app: `maridive_fleet_vessels`
Stack this plan builds on: **Flutter 3.44.6 · Supabase (Postgres + Auth + Storage + Edge Functions) · Provider · `CloudStore` generic table wrapper · `AttachmentStore` (Storage-backed files)**.

> This plan deliberately reuses what already exists. Every new data module is another
> `CloudStore('<table>')`; every file goes through `AttachmentStore` into the private
> `attachments` bucket; every provider follows the existing in-memory-cache +
> `onAuthStateChange` pattern with **unchanged public method signatures** so screens
> stay untouched. Nothing here introduces a second architecture.

---

## 0. Summary of the 9 requests

| # | Request | Core new pieces | Phase |
|---|---------|-----------------|-------|
| 1 | UI/UX polish (consistency, theming, responsive, a11y) | Design tokens, shared widgets, layout breakpoints | MVP |
| 2 | Universal file upload / download / in-app view + fail-safe | `FileService`, viewer registry, unsupported-format banner | MVP |
| 3 | Defect module: upload file → auto-extract → add to list | `extract` Edge Function (Gemini multimodal) → structured JSON | Phase B |
| 4 | Requisition module: upload → auto-extract → append | Same `extract` function, different schema | Phase B |
| 5 | Free-tier AI assistant (help + workflow guidance) | `assistant` Edge Function (Gemini free tier) proxy | Phase C |
| 6 | Crew area: "Current Crew List" + "Previous Crew List" | `crew_members` table w/ status + history | Phase C |
| 7 | Unified export (any module → PDF/CSV, one action) | `ReportService` + `printing`/`csv` | Phase C |
| 8 | Port call subsection: "Vessel Requirements Upon Arriving at Port" | `port_requirements` table + file attachments | Phase B |
| 9 | Notifications → assignable actions to management (status, due date, assignee) | Extend `urgent_notifications` data shape + filters | MVP |

Recommended order (details in §7): **MVP → B → C**. Ship value early; put the AI/extraction pieces behind the file-handling foundation they depend on.

---

## 1. Data model sketch

Everything continues to live in the `CloudStore` shape:

```
create table <name> (
  id          text primary key,
  vessel_id   text,
  data        jsonb not null,     -- the model's toMap()
  updated_at  timestamptz default now()
);
alter table <name> enable row level security;
create policy "fleet users full access" on <name>
  for all to authenticated using (true) with check (true);
```

So "adding a module" = one migration + one provider. New/changed logical entities:

### 1.1 Crew (request 6) — table `crew_members`

| field | type | notes |
|-------|------|-------|
| `id` | text | `${vesselId}_${uuid}` |
| `vesselId` | text | which vessel |
| `name` | string | |
| `rank` | string | Master, C/O, C/E, AB, Oiler… |
| `nationality` | string | |
| `status` | enum | `current` \| `previous` |
| `signOnDate` | date | |
| `signOffDate` | date? | set when moved to `previous` |
| `photoPath` | string? | Storage path (avatar) |
| `notes` | string? | |

History is intrinsic: moving a member to "Previous" is a status flip + `signOffDate` stamp, never a delete. "Current Crew List" = `where status == current`, "Previous" = `where status == previous`, sorted by `signOffDate desc`.

### 1.2 Port requirements (request 8) — table `port_requirements`

| field | type | notes |
|-------|------|-------|
| `id` | text | |
| `vesselId` | text | |
| `portCallId` | text? | optional link to a specific `port_calls` row |
| `title` | string | e.g. "Pre-arrival checklist — Rotterdam" |
| `category` | string | Documents / Customs / Health / Security … |
| `attachments` | `List<Attachment>` | PDFs, Word, images — via `AttachmentStore` |
| `status` | enum | `pending` \| `ready` |
| `createdAt` | timestamptz | |

### 1.3 Notification actions (request 9) — extend `urgent_notifications` `data`

No new table. Add optional fields to the existing notification model (all nullable → backward compatible):

| new field | type | notes |
|-----------|------|-------|
| `isAction` | bool | true = it's an assigned task, not just an alert |
| `assignee` | string? | username or free-text name |
| `status` | enum | `pending` \| `in_progress` \| `completed` |
| `dueDate` | date? | |
| `completedAt` | timestamptz? | |

### 1.4 Attachments (requests 2, 3, 4, 8) — already exists

`Attachment { name, mimeType, storagePath?, dataBase64 }` with `isCloud => storagePath != null`. Keep as-is. Add `sizeBytes` and `uploadedBy` for auditing (both optional).

### 1.5 AI assistant (request 5) — no persistent table required for MVP

Conversation is ephemeral in-memory. **Optional** `ai_messages(id, user, role, content, created_at)` only if you want cross-device chat history later. Skip for MVP.

### Relationships (logical, enforced in app not DB — matches current design)

```
vessel_profiles 1─┬─* crew_members
                  ├─* port_requirements ──* attachments (Storage)
                  ├─* port_calls ──0..1 port_requirements
                  ├─* defects        ──* attachments
                  ├─* requisitions   ──* attachments
                  ├─* tank readings/notes/defects/requisitions
                  └─* urgent_notifications (some are "actions")
```

---

## 2. File storage approach

**One rule: files never live in Postgres `data` jsonb.** They go to the private
`attachments` Storage bucket via `AttachmentStore`; the row only stores the `path`.
This is already true for spec PDFs and picker attachments — extend it to every module.

- **Upload**: `file_picker` (cross-platform: Win/macOS/Android/Web) → bytes →
  `AttachmentStore.upload(name, bytes)` → returns `Attachment{storagePath}`.
- **Download**: `AttachmentStore.bytes(a)` → `Uint8List`; on desktop/mobile save via
  `file_saver`/share sheet, on web trigger a browser download (anchor blob).
- **View in-app**: viewer registry keyed by mime (see §3.2).
- **Path convention**: `<module>/<vesselId>/<micros>_<safeName>`, e.g.
  `port_reqs/MV001/173..._customs.pdf`. Idempotent seeds use fixed paths (as specs do).
- **Access**: bucket stays **private**; RLS on Storage already restricts to authenticated.
  Never expose public URLs. Downloads go through the authenticated Supabase client.

Quota reality (free tier): Storage 1 GB, DB 500 MB. Files-in-Storage (not base64-in-DB)
is what keeps you under the DB cap. Add a soft per-file guard (e.g. warn > 25 MB).

---

## 3. UI/UX design notes (request 1 + 2)

### 3.1 Design tokens & shared widgets

Create `lib/theme/app_theme.dart` (single source of truth) and stop hand-styling per screen:

```dart
class AppTokens {
  static const brand = Color(0xFF0B4F8A);   // Maridive blue
  static const gapS = 8.0, gapM = 16.0, gapL = 24.0;
  static const radius = 12.0;
}

ThemeData maridiveTheme(Brightness b) => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: AppTokens.brand,
  brightness: b,
  cardTheme: CardTheme(shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppTokens.radius))),
);
```

Shared widgets to extract (used everywhere → consistency for free):
`SectionCard`, `EmptyState`, `StatusChip(status)`, `PrimaryButton`, `AttachmentPickerStrip` (exists), `AppScaffold` (title + RTL-aware back + optional actions).

### 3.2 Responsive layout

One breakpoint helper, used by every module list/detail:

```dart
enum FormFactor { compact, medium, expanded }
FormFactor formFactorOf(BuildContext c) {
  final w = MediaQuery.sizeOf(c).width;
  if (w < 600) return FormFactor.compact;   // phone
  if (w < 1024) return FormFactor.medium;   // tablet / small window
  return FormFactor.expanded;               // desktop / web
}
```

- compact → single column, bottom nav.
- medium/expanded → master-detail (list left, detail right), `NavigationRail`.
  This directly helps Windows/macOS/Web where the current phone layout wastes space.

### 3.3 Accessibility & RTL

- Keep everything inside `Directionality` (already driven by locale). Use
  `EdgeInsetsDirectional` / `start`/`end`, never `left`/`right`.
- Min tap target 48×48; `Semantics(label:…)` on icon-only buttons.
- Don't encode meaning in color alone — pair `StatusChip` color with text.
- Respect text scaling: avoid fixed-height rows; use `min`-constrained layouts.
- Contrast ≥ 4.5:1 (the brand blue on white passes; check chips).

### 3.4 In-app file viewer registry (the fail-safe is the point)

```dart
Widget viewerFor(Attachment a, Uint8List bytes) {
  final m = a.mimeType;
  if (m.startsWith('image/'))       return InteractiveViewer(child: Image.memory(bytes));
  if (m == 'application/pdf')       return PdfPreview(build: (_) => bytes); // printing pkg
  if (m.startsWith('text/'))        return SingleChildScrollView(
                                      child: Text(utf8.decode(bytes)));
  // Word/Excel/PowerPoint & everything else → graceful fallback
  return UnsupportedFilePane(a: a); // "Can't preview .docx in-app" + Download/Open buttons
}
```

`UnsupportedFilePane` = clear message + **Download** + **Open in external app** (share
sheet on mobile, `open_filex`/`url_launcher` on desktop/web). This is the "robust
fail-safe with clear messaging" — never a blank screen or crash on `.docx`, `.xlsx`, `.dwg`.

---

## 4. Auto-extraction (requests 3 & 4)

**Decision: do extraction server-side in one `extract` Edge Function using a multimodal
LLM (Gemini free tier), not on-device OCR.** Why:

- On-device OCR (`google_mlkit_text_recognition`) is **mobile-only** — breaks Win/macOS/Web.
- PDF text extraction packages have licensing/format gaps (scanned PDFs have no text layer).
- A multimodal model reads PDFs **and** photos **and** returns *structured* fields directly
  (not raw text you then have to parse). One code path, all platforms, all file types.

### Flow

```
User uploads file in Defect/Requisition module
      │  (already stored via AttachmentStore → storagePath)
      ▼
App calls Edge Function `extract` { storagePath, kind: 'defect' | 'requisition' }
      ▼
Edge Function: download bytes from Storage (service role) → send to Gemini with a
      JSON-schema prompt → return validated JSON
      ▼
App shows a PRE-FILLED review sheet (never auto-commit blind) → user confirms →
      provider.add(Defect.fromExtraction(json))  attaching the original file
```

Extraction schemas:

```jsonc
// defect
{ "equipment": "", "description": "", "severity": "low|medium|high|critical",
  "reportedDate": "YYYY-MM-DD", "recommendedAction": "" }
// requisition
{ "items": [{ "partNo": "", "description": "", "qty": 0, "unit": "" }],
  "vessel": "", "requestedBy": "", "neededByDate": "YYYY-MM-DD" }
```

**Human-in-the-loop is required**: always show the extracted data in an editable review
sheet before it enters the list. This is both a UX and a correctness safeguard (see
acceptance thresholds in §9).

---

## 5. AI assistant (request 5)

**Decision: Supabase Edge Function proxy holding the API key server-side; the Flutter
client never sees a key.** Embedding an LLM key in a distributed desktop/mobile/web app
would leak it instantly.

### Provider choice (free, no cost to users)

| Option | Free tier | Multimodal | Notes |
|--------|-----------|-----------|-------|
| **Google Gemini API** (recommended) | Generous free RPM/RPD on Flash | ✅ (reuse for §4) | One key covers assistant **and** extraction |
| Groq (Llama-3.x) | Fast, free tier | ❌ text only | Great latency, but no vision → still need Gemini for §4 |
| Cloudflare Workers AI | Free allocation | limited | More infra to run |

Pick **Gemini Flash** so requests 3, 4, and 5 share one function + one key + one quota.

### Edge Function `assistant` (sketch)

```ts
// supabase/functions/assistant/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
const KEY = Deno.env.get("GEMINI_API_KEY")!;         // set via `supabase secrets set`
const SYSTEM = `You are the Maridive Fleet assistant. Help crew use the app:
explain how to log tank readings, raise defects/requisitions, manage port
requirements and crew lists. Be concise. Never invent vessel data.`;

serve(async (req) => {
  const { messages } = await req.json();             // [{role, content}]
  const r = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${KEY}`,
    { method: "POST", headers: { "content-type": "application/json" },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM }] },
        contents: messages.map(m => ({ role: m.role === 'assistant' ? 'model' : 'user',
                                       parts: [{ text: m.content }] })),
      }) });
  const j = await r.json();
  const text = j.candidates?.[0]?.content?.parts?.[0]?.text ?? "…";
  return new Response(JSON.stringify({ text }), { headers: { "content-type": "application/json" } });
});
```

Client call (reuses the authenticated Supabase client — JWT enforced by `verify_jwt`):

```dart
final res = await supabase.functions.invoke('assistant',
    body: {'messages': history.map((m) => m.toJson()).toList()});
final reply = (res.data as Map)['text'] as String;
```

### Rate limits, cost, privacy

- **Cost to users: zero** — key is yours, on the free tier. Add a per-user throttle in the
  function (e.g. count invocations/minute in a `ai_usage` table) so one user can't burn the
  quota. Return a friendly "assistant busy, try again shortly" on 429.
- **Privacy**: the assistant is for **how-to help**, not for piping the vessel database to a
  third party. Do **not** auto-send fleet records to Gemini. Send only the user's typed
  question + the static system prompt. If you later add data-aware answers, gate them and
  tell the user their question text leaves the app. Passports/PII must never be sent.
- Keep a visible disclaimer: "AI answers may be wrong — verify against official procedures."

---

## 6. Unified export (request 7)

Extend the existing "Export report for tanks" into a **`ReportService`** that any module
feeds. One action → choose format → choose modules → generate.

```dart
abstract class Exportable {
  String get sectionTitle;
  List<String> get columns;
  List<List<String>> get rows;     // each module maps its records to rows
}

class ReportService {
  static Future<Uint8List> pdf(List<Exportable> sections, {required String vessel}) {
    final doc = pw.Document();
    for (final s in sections) {
      doc.addPage(pw.MultiPage(build: (_) => [
        pw.Header(text: '$vessel — ${s.sectionTitle}'),
        pw.TableHelper.fromTextArray(headers: s.columns, data: s.rows),
      ]));
    }
    return doc.save();                              // `pdf` + `printing` packages
  }

  static String csv(Exportable s) =>               // `csv` package
    const ListToCsvConverter().convert([s.columns, ...s.rows]);
}
```

Each provider implements `Exportable` (Defects, Requisitions, Tanks, Port Calls, Crew,
Notifications). The export dialog is checkbox list of sections + PDF/CSV toggle + one
"Generate" button → `Printing.sharePdf` / download. Because it's an interface, adding a new
module to export later is one small class, not a rewrite.

---

## 7. MVP roadmap (phased)

**MVP (foundation + quick wins)** — no external AI, unblocks everything else
1. `app_theme.dart` + shared widgets + responsive helper (request 1).
2. `FileService` + `file_picker` wiring + viewer registry + `UnsupportedFilePane`
   fail-safe (request 2). This is the backbone reused by 3, 4, 8.
3. Notification actions: extend model + assignee/status/due filters + a "My tasks"
   view (request 9). Pure local model change, high management value.

**Phase B (files everywhere + extraction)**
4. Port requirements module under Port Calls (request 8) — new `port_requirements`
   `CloudStore` + provider + screen, using the §2 file stack.
5. `extract` Edge Function + review sheets in Defect (3) and Requisition (4) modules.

**Phase C (assistant + crew + export)**
6. `assistant` Edge Function + chat panel + throttle table (request 5).
7. `crew_members` module with Current/Previous tabs + history (request 6).
8. `ReportService` unified export across all modules (request 7).

**Phase D (hardening)** — roles (Master/Office/Crew), Storage size guards, optional
realtime, PII handling review, audit fields.

Rationale: 2 must precede 3/4/8 (they all upload files). 5 (assistant infra) precedes
nothing else, so it slots wherever; it shares the Gemini key with 3/4 so do those first to
prove the function pattern.

---

## 8. Implementation steps (per module, the repeatable recipe)

For each new data module (crew, port requirements) you repeat the proven pattern:

1. **Migration** in `supabase/migrations/` — the `CloudStore` table + RLS policy (§1).
2. **Model** `lib/models/<x>.dart` with `toMap()/fromMap()` (files as `storagePath`).
3. **Provider** `lib/state/<x>_provider.dart`:
   ```dart
   class CrewProvider extends ChangeNotifier {
     final _store = CloudStore('crew_members');
     final List<CrewMember> _all = [];
     CrewProvider() {
       supabase.auth.onAuthStateChange.listen((s) {
         if (s.event == AuthChangeEvent.signedOut) { _all.clear(); notifyListeners(); }
         else { _load(); }
       });
     }
     Future<void> _load() async {
       final rows = await _store.fetchAll();
       _all..clear()..addAll(rows.map((r) => CrewMember.fromMap(r)));
       notifyListeners();
     }
     List<CrewMember> current(String v)  => _all.where((c) => c.vesselId==v && c.status==CrewStatus.current).toList();
     List<CrewMember> previous(String v) => _all.where((c) => c.vesselId==v && c.status==CrewStatus.previous).toList();
     Future<void> save(CrewMember c) async {           // optimistic write-through
       _all..removeWhere((x)=>x.id==c.id)..add(c); notifyListeners();
       await _store.upsert(c.id, c.toMap(), vesselId: c.vesselId);
     }
     Future<void> signOff(CrewMember c) =>              // history, not delete
       save(c.copyWith(status: CrewStatus.previous, signOffDate: DateTime.now()));
   }
   ```
4. **Register** the provider in `main.dart` (no-arg constructor, `MultiProvider`).
5. **Screen** using the shared widgets + responsive master-detail.
6. **Export** — implement `Exportable` on the provider (Phase C).

Edge Functions (`extract`, `assistant`): `supabase functions deploy <name>` with
`supabase secrets set GEMINI_API_KEY=…`. Add both to `supabase/config.toml` with
`verify_jwt = true` (mirrors the `admin-users` entry).

---

## 9. Testing, validation & acceptance criteria

### Acceptance criteria per request

1. **UI/UX** — every screen uses `maridiveTheme`; light+dark render; RTL mirrored; no
   layout overflow at 360 px, 768 px, 1280 px; icon buttons have semantics labels.
2. **File handling** — upload/download works for PDF, PNG/JPG, TXT, DOCX, XLSX on all 4
   platforms; PDF/image/text preview in-app; unsupported types show the fallback pane with
   a working Download + Open-external (0 crashes / 0 blank screens on any extension).
3. **Defect extraction** — ≥ 80% field-level accuracy on clean typed PDFs; scanned/photo
   inputs still return a usable draft; **100% of extractions pass through the editable
   review sheet** before entering the list; original file is attached to the created defect.
4. **Requisition extraction** — line items parsed with qty+unit; same review-sheet gate; a
   50-line requisition extracts in < 15 s.
5. **AI assistant** — answers general app-usage questions; median latency < 4 s; per-user
   throttle returns a friendly message on 429; disclaimer visible; **no vessel data or PII
   sent** to the provider; costs users nothing.
6. **Crew** — Current and Previous lists correct; sign-off moves a member to Previous with a
   date and never deletes; history survives app restart and syncs across devices.
7. **Export** — select any subset of modules → single PDF with a section per module, and
   per-module CSV; opens/shares on all platforms; Arabic text renders in the PDF (embed a
   Unicode font, e.g. Noto Naskh, or Arabic shows as boxes).
8. **Port requirements** — subsection under Port Calls; upload/download/view any file type;
   status pending→ready; attachments sync via Storage.
9. **Notifications** — an alert can be flagged as an action with assignee + due date +
   status; "My tasks" filters by assignee; overdue highlighted; status transitions persist.

### Test checklist

- **Unit**: model `toMap/fromMap` round-trips (incl. new nullable fields → old rows still
  parse); provider filters (current/previous, my-tasks, overdue).
- **Widget**: viewer registry returns the right pane per mime incl. the fallback; review
  sheet is editable and cancelable.
- **Integration (Supabase)**: each new table CRUD via `CloudStore` (201/200/204); Storage
  upload/download/round-trip; Edge Function `extract`/`assistant` happy path + 429 + bad
  input; RLS blocks anon.
- **Cross-platform smoke**: build + launch Win/macOS/Android/Web from CI artifacts; login;
  upload a file; view it; run an export.
- **Regression**: existing modules (tanks, port calls, certs, specs) still load — the
  additive nullable fields must not break old data.
- **RTL/locale**: switch to Arabic; verify mirroring and PDF Arabic glyphs.
- **Negative**: upload a 0-byte file, a huge file, a `.dwg`, a corrupt PDF → graceful msgs.

---

## 10. Deployment & rollback

**Deploy**
- App: push to `main` → GitHub Actions builds Win/macOS/Android/Web (Flutter 3.44.6). Web
  build already uses `--no-web-resources-cdn`; re-publish `build/web` to Netlify for crew.
- DB: additive migrations only (new tables, new nullable fields) — never drop/rename
  columns in a release. Apply via `supabase db push` (or Dashboard SQL) before shipping the
  app build that reads them.
- Edge Functions: `supabase functions deploy extract assistant`; set `GEMINI_API_KEY`
  secret. Both gated by `verify_jwt`.

**Feature flags**: gate 5 (AI) and 3/4 (extraction) behind a `settings` flag so you can dark-
launch and disable instantly if the Gemini quota is hit — no app rebuild needed.

**Rollback**
- App: redeploy the previous CI artifact / previous Netlify deploy (Netlify keeps deploy
  history — one-click rollback).
- DB: because migrations are additive + fields nullable, an older app build ignores new
  columns safely → rollback = just ship the old app; no destructive DB revert needed.
- Edge Functions: `supabase functions delete <name>` or redeploy prior version; the app
  should degrade gracefully (extraction/assistant show "temporarily unavailable").

**Backups**: enable Supabase daily backups (or periodic `pg_dump`); Storage is the system of
record for files — do not also delete files on row delete without a soft-delete grace period.

---

## 11. New dependencies (all free / permissive)

| package | for | platforms |
|---------|-----|-----------|
| `file_picker` | pick any file to upload | all |
| `printing` + `pdf` | PDF preview + export | all |
| `csv` | CSV export | all |
| `open_filex` or `url_launcher` | open unsupported files externally | all |
| `file_saver` | save downloads on desktop/web | all |
| (existing) `supabase_flutter`, `provider` | backend + state | all |

Server: Gemini API key (free tier) in Edge Function secrets. No paid services.

---

## 12. Confirmed decisions (locked 2026-07-13)

These were reviewed and chosen by the product owner; the rest of the plan is written to
match them.

1. **AI scope → Full AI.** Use free **Gemini Flash** for both auto-extraction (defects &
   requisitions) and the help assistant. One key, one quota, server-side in an Edge Function.
2. **First release → Foundation MVP.** UI/UX polish + universal file upload/download/view +
   assignable notifications ship first (backbone for extraction & port requirements).
3. **Crew PII → Minimal only.** Store name, rank, nationality, sign-on/off dates. **No
   passport numbers** (drop `passportNo` from §1.1). Lower privacy risk.
4. **Roles → Later (Phase D).** All authenticated users have full access for now, as today.
5. **Assistant reach → Help-only.** Answers how-to/workflow questions. **No vessel data or
   PII is ever sent** to the AI provider. (Removes the §5 "data-aware" option.)
6. **Export Arabic → Bundle Noto Naskh Arabic.** Exported PDFs render Arabic correctly.
7. **Office files → Download + open externally.** PDF/image/text preview in-app; Word/Excel/
   PowerPoint show the `UnsupportedFilePane` with Download + Open-in-external-app. No
   server-side conversion.
8. **AI chat history → Session-only.** Chat is in-memory; no `ai_messages` table. Simplest
   and most private.
```
