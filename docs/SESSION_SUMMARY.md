# MARIDIVE FLEET VESSELS — Project & Session Summary

_Last updated: 2026-07-11_

Bilingual (EN / AR, with RTL) Flutter cross-platform fleet-management app.

- **Repo:** https://github.com/mohammedamin74/maridive-fleet-vessels (branch `main`)
- **Local path:** `/Users/mohamedamin/development/projects/maridive_fleet_vessels`
- **CI:** GitHub Actions builds Windows / macOS / Android / Web
- **Flutter:** 3.44.6 (`~/development/flutter-3.44.6/bin/flutter`), Dart, Provider state management
- **Cloud backend:** Supabase (Postgres + Auth + Storage + Edge Functions) — free tier, includes file storage

---

## 1. What the app does

A shared, multi-user fleet system for the MARIDIVE vessels. Each vessel has:

- Tank calculators + manual readings + history graph with high/low alarms
- Logbook / notes (all file formats)
- Defect list (all file formats, PDF export)
- Requisitions (all file formats)
- Port Call logistics (all file formats)
- Certifications (vessel + crew)
- Urgent Notifications / Alert Center
- Daily Tasks (all file formats)
- **Maintenance** — separate section, any-format upload
- **Specifications** — document library of the vessel spec PDFs (5 preloaded)
- Vessel status toggle (active / off-hire-inactive), manually editable IMO number
- Vessel hero photo extracted from each spec PDF, shown on cards/detail
- Home Port = Alexandria, Egypt; Working Port = Tripoli

Per-person **username + password login** (admin creates accounts). Session persists across launches.

---

## 2. Cloud architecture (Supabase)

**Config** — `lib/services/supabase_config.dart`
- url: `https://forcpesacwaektzyslyh.supabase.co`
- publishableKey: `sb_publishable_LHfol9Srr5_CmV7HKGuPQg_j6hwE4QV` (PUBLIC — safe in the app)
- `init()` → `Supabase.initialize(url, publishableKey)`; called in `main()` before Hive.

> **SECURITY:** the `service_role` / secret key and the DB password must **never** be in the app — only inside Edge Functions. The publishable key above is public and safe.

**Auth** — `lib/state/auth_provider.dart`
- username → synthetic email `username@maridive.app`
- `login()` → `signInWithPassword`; `logout()` → `signOut`
- `addUser` / `removeUser` / `changePassword` → call Edge Function `admin-users` (service_role, admin-verified server-side)
- own-password change → `updateUser`
- Default admin: **`admin` / `Maridive@2026`**

**Generic table design** — every module table is:
```
(id text pk, vessel_id text, data jsonb, updated_at timestamptz)
```
The app stores its existing `toMap()` output as the `data` jsonb. RLS: any authenticated user has full access.

**CloudStore** — `lib/services/cloud_store.dart`: thin wrapper (`fetchAll` / `put` / `remove`) over one table.

**Cloud provider pattern** (keeps screens untouched — method signatures unchanged):
- In-memory cache loaded via `CloudStore.fetchAll()` on `onAuthStateChange` (signedIn / initialSession / tokenRefreshed)
- Cleared on signedOut
- Optimistic writes: update cache + `notifyListeners()`, then `put` to cloud

**Schema & functions**
- `supabase/schema.sql` — profiles table + `handle_new_user()` trigger, all module tables with RLS, private `attachments` storage bucket + policies.
- `supabase/functions/admin-users/index.ts` — Deno Edge Function; verifies caller is admin, then create/delete/reset users; protects the `admin` user.

---

## 3. Migration phases

- **Phase 1 — Auth (DONE, commit `e7fff92`):** Supabase auth, login screen, user management, `_AuthGate`.
- **Phase 2 — Cloud-sync data modules (IN PROGRESS):**
  - ✅ **Maintenance** — migrated & verified end-to-end (commit `4ae11d6`). Write returned HTTP 201, read-back correct, "1 open" showed after reload, session auto-restored.
  - ⏭️ Remaining, same pattern: TankDataProvider (readings, notes/logbook, defects, requisitions), PortCallProvider, CertificationProvider (vessel_certs, crew_certs), UrgentNotificationProvider, DailyTasksProvider, VesselSpecProvider, VesselProfileProvider (status/IMO overrides).
- **Phase 3 — Attachments → Supabase Storage:** base64-in-jsonb breaks on large PDFs / realtime ~1 MB limit; specs migration pairs with this.
- **Phase 4 — Roles & final security; optional realtime** (add tables to `supabase_realtime` publication).

---

## 4. Key models & widgets

- `lib/models/attachment.dart` — `Attachment` (name + base64), generalizes photos to any file type.
- `lib/widgets/attachment_picker.dart` — `AttachmentPickerStrip`; PDF tap-to-open via `Printing.sharePdf`.
- `lib/models/maintenance_record.dart`, `lib/screens/maintenance_list_screen.dart`.
- `lib/models/vessel_spec.dart` + `lib/state/vessel_spec_provider.dart` + `lib/screens/vessel_specs_screen.dart`.
- `lib/data/vessel_specs_seed.dart` — seeds 5 spec PDFs; `assets/specs/*.pdf` (5).
- `assets/vessels/mrd-*.jpg` (5) — cropped hero photos.
- `lib/models/vessel.dart` — added workingPort, off-hire status, photoAsset, copyWith.
- `lib/data/fleet_data.dart` — Alexandria/Tripoli, photoAsset per vessel.
- `lib/state/vessel_profile_provider.dart` — status/IMO overrides.

Dependencies added: `supabase_flutter ^2.8.0`, `file_picker`, `pdf` / `printing`, `crypto`.

---

## 5. Notable fixes / gotchas

- macOS build needed full Xcode + `sudo xcodebuild -license accept`; CocoaPods upgraded to 1.17.0; macOS build needs `LANG=en_US.UTF-8`.
- `/usr/bin/python3` is a gated shim → launch.json runs `/usr/bin/env DEVELOPER_DIR=/Library/Developer/CommandLineTools python3 ...`.
- `flutter run -d macos` backgrounded dies → build the `.app` and `open` it standalone (installed to /Applications).
- Commit messages with apostrophes → write message to a file + `git commit -F`.
- `flutter gen-l10n` must be run from the project dir (not home) or getters don't regenerate.
- Flutter **web** canvas text input via DOM value-set does NOT reliably commit to controllers — verify the cloud path via the app's live Supabase session token (REST write + read-back) instead.
- Vessel photo extraction: macOS `qlmanage -t -s 1600` to rasterize PDF page 1, then Pillow to crop.

---

## 6. Outstanding user action

- **Deploy the `admin-users` Edge Function** from the Supabase Dashboard (Edge Functions → Deploy → name it `admin-users`, paste `supabase/functions/admin-users/index.ts`) to enable in-app user creation.
