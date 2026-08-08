# Slate — handoff / next steps

Context for the next agent picking up this repo. Read this together with
`docs/BRIEF.md` (expanded domain + DoD), `docs/ROADMAP.md` (phases), and
`docs/TICKETS.md` (work items with acceptance criteria + dependencies).

## Original goal

A lean Hanami practice app demonstrating **scheduled / draft changes** to editable
models, built TDD + DDD. Now being extended (a) into a richer multi-venue café domain
and (b) with the hardening/features that real scheduled-change systems need. Work is
organised as tickets in `docs/TICKETS.md`, implemented in waves of parallel subagents
(Sonnet) with an Opus "senior" reviewing/merging each PR.

## Current state (as of this handoff)

- **Branch:** `main` only. Clean working tree. Suite **green: `bundle exec rspec` → 76 examples, 0 failures.**
- **Repo:** https://github.com/adilw3nomad/slate (public).
- **Baseline mechanism (pre-existing):** one polymorphic `scheduled_changes` table; `Changes::Stage`
  writes a pending change (draft = no `apply_at`, scheduled = `apply_at` set); `Changes::Apply`
  merges `new_values` onto the target via a dispatch map (`{"MenuItem" => :menu_item_repo}`) and
  marks it applied; `Changes::ApplyDue` + `bin/sweep` is the DB-backed runner (no Sidekiq/Redis).
- **SLATE-001 (done):** `scheduled_changes` now carries every column later phases need —
  `base_values`, `expires_at`, `attempts`, `last_error`, `locked_at`, `locked_by`, `next_run_at`,
  `author_id`, `applied_by`. Status vocabulary: `pending, applied, cancelled, conflicted, failed, expired, superseded`.
- **Wave 1 (done, all merged):**
  - SLATE-022 expiry — `Changes::ExpireStale`; `expires_at` past-due → `expired`, not applied; runs first in `bin/sweep`.
  - SLATE-013 observability — `sweep_runs` table + `SweepRunRepo` + `GET /runs` page; `bin/sweep` logs each run.
  - SLATE-011 resilient runner — `ApplyDue` claims rows (`locked_by/at`), retries with exponential
    backoff (`2**attempts`, `next_run_at`), marks `failed` at 5 attempts; `Changes::ReapStuck` clears stale locks.
  - SLATE-010 apply-time re-validation — `Apply` re-runs `ChangeContract`; invalid → `failed` + `last_error`, target untouched.

## Work remaining (in priority order)

1. **Phase 0 enrichment — SLATE-002, 003, 004, 005** (serial, shared-state; NOT parallel-safe).
   Venues + MenuSections (MenuItem moves under a Section), Promotions, Users + role
   (`current_user`), then register all four models in `Changes::Apply::REPOS` + enriched seeds.
   Full acceptance criteria in `docs/TICKETS.md`. This is the prerequisite for Wave 2.
2. **SLATE-014** (follow-up, T1): `ApplyDue` currently counts a validation-`Failure` from `Apply`
   as "applied" (non-exception result treated as success) — inflates `applied_count`. Make
   `ApplyDue` inspect the result and count only successes; wire real `failed_count`/`conflicted_count`
   into `sweep_runs` (currently hardcoded 0). Deps: 010, 011, 013.
3. **Wave 2** (parallel-safe once Phase 0 lands): SLATE-020 conflict detection (base snapshot +
   drift → `conflicted`), 021 superseding, 022 already done; then governance (030 attribution,
   031 approval, 032 undo), 040 timezone/DST, 041 recurrence, 050 as-of preview. See `docs/TICKETS.md`.

## How to continue (the workflow that's been used)

- **Senior (Opus) lays shared-state/foundation work directly** (schema, enrichment, dispatch-map
  registration, seeds). **Leaf features go to parallel Sonnet subagents**, one ticket each, in
  isolated git worktrees, each opening a **GitHub PR** against `main`.
- **Senior reviews each PR vs its acceptance criteria, then merges serially**, rebasing later
  branches so shared-file seams resolve one at a time. In Wave 1 the shared seams were
  `app/repos/scheduled_change_repo.rb` (append-only method additions) and `bin/sweep`
  (each feature adds one line to `def sweep`). Merge order was chosen to minimise cascade.
- Carve parallel tickets to touch **different files/operations**; front-load schema so tickets
  add logic, not migrations. Don't parallelise the sweep pipeline itself — it's one cohesive unit.

## Critical gotchas (will bite a fresh agent)

- **`Slate::Operation` (dry-operation): `call`'s return value is auto-wrapped in `Success`.
  Return the RAW value, never `Success(x)` (double-wraps).** Use `step result` to unwrap a Result
  and short-circuit; `Failure(:reason)` to fail. See `app/changes/apply.rb`.
- **Worktrees have no DB** — `db/*.sqlite` is gitignored. In any fresh checkout/worktree run
  `bundle exec hanami db prepare` AND `HANAMI_ENV=test bundle exec hanami db prepare` before tests.
- **DB writes require a fresh server connection.** Resetting the DB (`hanami db drop/prepare`)
  while `hanami server` is running leaves it read-only — restart the server.
- **macOS built-in `awk` lacks `strftime`** (irrelevant to the app; only bit an earlier shell task).
- **`Hanami.app["some.component"]` is not memoized identically across calls in tests** — stubbing a
  resolved operation (`allow(Hanami.app["changes.apply"]).to receive(...)`) does NOT intercept calls
  made inside another already-resolved operation. To make `Apply` fail for a runner test, stage a
  change with malformed `new_values` (`"not-json"`) so it raises for real. (Found during SLATE-011.)
- **Repo update guards:** status transitions use `.by_pk(id).where(status: "pending").changeset(:update, …).commit`
  for idempotency (see `mark_applied`, `mark_expired`, `mark_failed`). Follow that pattern.
- **Shell noise:** every command prints a harmless `zoxide` config warning to stderr — ignore it.
- **Commits:** no `Co-Authored-By` line (project preference).

## Conventions / layout

- Pure domain (framework-free): `lib/slate/` (`Money`, `ChangeSet`).
- Application operations: `app/changes/` (`Slate::Changes::*`, container key `changes.*`).
- Persistence: `app/relations/` (ROM, `schema :table, infer: true`) + `app/repos/` (`Slate::Repos::*Repo`).
- Validation: `app/contracts/` (dry-validation).
- Web: `app/actions/`, `app/views/` (`expose :key`), `app/templates/` (ERB); action sets `response[:key]`.
  Layout `app/templates/layouts/app.html.erb` holds the nav + all inline CSS (no asset build step).
- Tests: RSpec; DB examples tagged `:db`; resolve components via `Hanami.app["…"]`; request specs
  `type: :request`. Every ticket is TDD — failing test first.
- Migrations: `bundle exec hanami generate migration NAME`, edit, then `hanami db migrate`
  (and `HANAMI_ENV=test …`). All later columns already exist from SLATE-001.

## Verification

`bundle exec rspec` (76 examples green). `bin/sweep` runs expire → apply → record and writes a
`sweep_runs` row. `/`, `/changes`, `/runs` render (seed data via `hanami db prepare`).
