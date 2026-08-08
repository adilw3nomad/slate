# Slate — tickets

Each ticket: **Depends on**, **DoD tier**, **Touches** (files/areas, for conflict-awareness),
**Parallel-safe**, and testable **Acceptance criteria**. TDD is mandatory — every AC is a test
written first.

Legend — Parallel-safe: ✅ can run alongside its wave · ⚠️ minor shared-file overlap (senior
integrates) · ❌ foundational/serial.

---

## Phase 0 — Foundation (serial; owned by senior)

### SLATE-001 — Provision full `scheduled_changes` schema
- **Depends on:** none · **Tier:** T1 · **Parallel-safe:** ❌
- **Touches:** `config/db/migrate/*`, `app/relations/scheduled_changes.rb`
- **Why:** front-load every column later phases need so parallel tickets add *logic*, not migrations.
- **AC:**
  - [ ] Migration adds: `base_values` (JSON), `expires_at`, `attempts` (int, default 0),
        `last_error` (text), `locked_at`, `locked_by`, `next_run_at`, `author_id`, `applied_by`.
  - [ ] Status vocabulary documented: `pending, applied, cancelled, conflicted, failed, expired, superseded`.
  - [ ] Existing suite stays green (new columns nullable / defaulted).

### SLATE-002 — Venues + Sections; MenuItem under a Section
- **Depends on:** none · **Tier:** T2 · **Parallel-safe:** ❌
- **Touches:** migrations, relations/repos (venues, menu_sections, menu_items), board UI, seeds.
- **AC:**
  - [ ] `venues` (name, timezone) and `menu_sections` (venue_id, name, position) tables + repos.
  - [ ] `menu_items` gains `section_id`; repo can list items by section.
  - [ ] Board renders Venue → Section → Item; repo/round-trip specs pass.

### SLATE-003 — Promotions
- **Depends on:** SLATE-002 · **Tier:** T2 · **Parallel-safe:** ❌
- **Touches:** migration, relations/repos (promotions), a promotions view.
- **AC:**
  - [ ] `promotions` (venue_id, name, discount_percent, starts_at, ends_at, active) + repo.
  - [ ] A promotions list view; repo specs cover active-window queries.

### SLATE-004 — Users + role + current_user
- **Depends on:** none · **Tier:** T2 · **Parallel-safe:** ❌
- **Touches:** migration, users repo, a `current_user` provider (session or demo switcher).
- **AC:**
  - [ ] `users` (name, role in {manager, staff}); a resolvable `current_user`.
  - [ ] A visible role indicator + a way to switch role for the demo.

### SLATE-005 — Register 4 models in dispatch + enriched seeds
- **Depends on:** SLATE-002, 003, 004 · **Tier:** T2 · **Parallel-safe:** ❌
- **Touches:** `app/changes/apply.rb` (dispatch map), `config/db/seeds.rb`.
- **AC:**
  - [ ] `Changes::Apply::REPOS` maps `Venue, MenuSection, MenuItem, Promotion` to repos.
  - [ ] `Changes::Stage`/`Apply` work against all four (spec per model).
  - [ ] Seeds create ≥2 venues with sections/items and a couple of promotions + pending changes.

---

## Wave 1 — Reliable runner (parallel; depends only on SLATE-001)

> Four slices carved to different files. **Merge order (senior): 013 → 022 → 011 → 010**,
> rebasing later PRs. `bin/sweep` is the only shared file — each adds one line; trivial to merge.

### SLATE-010 — Apply-time re-validation
- **Depends on:** SLATE-001 · **Tier:** T1 · **Parallel-safe:** ⚠️ (owns `app/changes/apply.rb` body)
- **AC:**
  - [ ] `Changes::Apply` re-runs `ChangeContract` against merged values before writing.
  - [ ] Invalid → change set to `failed` + `last_error`; **target left untouched**.
  - [ ] Valid path unchanged; specs for both.

### SLATE-011 — Resilient runner: retries, backoff, crash recovery
- **Depends on:** SLATE-001 · **Tier:** T1 · **Parallel-safe:** ⚠️ (owns `app/changes/apply_due.rb` + repo claim/retry methods)
- **AC:**
  - [ ] `ApplyDue` claims each due row (`locked_by`/`locked_at`) before applying; a second run skips claimed rows.
  - [ ] An apply that raises increments `attempts` and sets `next_run_at = now + backoff`; retried until a max, then `failed`.
  - [ ] `due` selection also respects `next_run_at`.
  - [ ] A `Changes::ReapStuck` requeues rows locked longer than a timeout.

### SLATE-013 — Sweep-run observability log
- **Depends on:** SLATE-001 · **Tier:** T2 · **Parallel-safe:** ✅ (new table + web view; no pipeline edits)
- **Touches:** new `sweep_runs` table/relation/repo, a `/runs` view, `bin/sweep` records one line.
- **AC:**
  - [ ] Each sweep writes a `sweep_runs` row (started_at, finished_at, applied_count, failed_count).
  - [ ] A `/runs` page lists recent runs, newest first.

### SLATE-022 — Expiry of stale scheduled changes
- **Depends on:** SLATE-001 · **Tier:** T1 · **Parallel-safe:** ✅ (new operation + repo query)
- **Touches:** new `Changes::ExpireStale` op, repo `expirable` query, `bin/sweep` calls it.
- **AC:**
  - [ ] A pending change past its `expires_at` is set to `expired` and **not applied**.
  - [ ] Changes without `expires_at` are unaffected.

---

## Wave 2+ — Backlog (deps noted; scheduled after Wave 1 + Phase 0 land)

- **SLATE-020** Base snapshot + drift → `conflicted` (Stage records `base_values`; Apply
  compares, refuses on drift). Deps: 001, 010. T2 (conflict banner).
- **SLATE-021** Superseding: staging a change to the same target+fields marks older pending
  ones `superseded`. Deps: 020. T1/T2.
- **SLATE-030** Attribution + audit: persist `author_id`/`applied_by`; an activity view.
  Deps: 004, 005. T2.
- **SLATE-031** Approval workflow: `draft → pending_approval → approved`; role checks.
  Deps: 004, 030. T2.
- **SLATE-032** Undo-after-apply: generate an inverse change from the pre-apply snapshot.
  Deps: 020. T2.
- **SLATE-040** Timezone/DST: store `apply_at` UTC + venue timezone; render venue-local.
  Deps: 002. T1/T2.
- **SLATE-041** Recurrence: a `Schedule` that generates one-shot changes (daily/weekly).
  Deps: 003. T2.
- **SLATE-050** As-of preview: render a model as it will look at a future date T.
  Deps: 001. T2/T3.
