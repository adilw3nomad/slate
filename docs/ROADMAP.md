# Slate — roadmap

Phases address the common failure modes of scheduled/draft-change systems, roughly in the
order they bite. Each ticket carries its DoD tier (see `BRIEF.md`). Work items live in
`TICKETS.md`.

## Already handled (baseline)
- At-least-once, idempotent apply (status-guarded update).
- Catch-up after downtime (`due = pending AND apply_at <= now`).

## Phase 0 — Enrich the model *(foundation, serial)*
Venue, MenuSection, Promotion, User/role; move MenuItem under a Section; register all four
editable models in the dispatch map; provision the full `scheduled_changes` schema up front
so later phases don't each need a migration. **Prerequisite for everything else.**

## Phase 1 — Reliable runner
Make the sweeper trustworthy. Apply-time re-validation, retries + backoff, crash recovery
(locking + reaper), and a sweep-run log for observability. Mostly T1.

## Phase 2 — Correctness against a moving target
Base snapshot + drift detection (`conflicted`), superseding of competing changes, and
expiry of stale scheduled changes. T1/T2.

## Phase 3 — Time correctness
Store `apply_at` in UTC + capture venue timezone (DST-safe); recurrence via a `Schedule`
concept that generates one-shot changes (daily happy-hour, seasonal windows). T1/T2.

## Phase 4 — Governance
Attribution (`author_id`, `applied_by`), approval workflow
(`draft → pending_approval → approved`), audit/activity view, and undo-after-apply via an
inverse change. T2.

## Phase 5 — Data-model generality
Nested/association changes, new-record drafts (schedule a create), config-driven model
registration. T1/T2.

## Phase 6 — Observability & UX
Cross-venue dashboard (pending/scheduled/failed/conflicted, upcoming timeline), notifications
on failed/conflicted, and an "as-of" preview (compose scheduled changes up to a future date).
T2/T3.
