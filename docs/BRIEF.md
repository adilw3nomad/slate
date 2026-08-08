# Slate — expanded brief

Slate is a Hanami practice app for **scheduled / draft changes** to editable models.
This brief expands the original single-aggregate café menu into a small multi-venue
hospitality system, rich enough to exercise the full range of scheduling extensions
(conflicts, approvals, expiry, recurrence, nested changes, multiple models).

## Domain

```
Venue ──< MenuSection ──< MenuItem
  └──────< Promotion   (window: starts_at / ends_at, discount)
User (role: manager | staff)   → drives approval & attribution
```

All four of `Venue`, `MenuSection`, `MenuItem`, `Promotion` are **editable models opted
into the scheduled-changes mechanism**, so `Changes::Apply`'s polymorphic dispatch map
grows from one entry to four — the "generalises to all editable models" claim becomes real.

| Model | Purpose | Unlocks |
|-------|---------|---------|
| Venue | café location (name, timezone) | multi-model dispatch; timezone/DST |
| MenuSection | ordered grouping under a venue | associations, nested changes |
| MenuItem | now belongs to a section | nested/section-move changes |
| Promotion | venue-scoped, time-windowed discount | expiry, superseding, recurrence, new-record drafts |
| User + role | manager vs staff | approval workflow, attribution, audit |

## Definition of Done (per capability)

Tiered, not one blanket bar:

- **T1 — Domain-only:** failing tests → operation/repo/VO → green. No UI. For invisible
  mechanics (retries, backoff, crash recovery, superseding).
- **T2 — Demoable:** T1 **+** a thin but real UI touchpoint **+** README/roadmap note.
  For anything a human interacts with (approvals, conflict banners, dashboards).
- **T3 — Polished:** T2 **+** visual polish & edge-case UX. Reserved for showcase pieces.

**Rule:** every capability is at least T1 (TDD always); human-facing capabilities reach T2;
T3 is opt-in for one or two headline features. The domain/operation layer is the product;
the UI demonstrates it.

## Principles carried over

- **TDD** — no production code without a failing test first.
- **DDD layering** — pure domain in `lib/slate`, application operations in `app/changes`,
  persistence in relations/repos, web on top.
- **Lean** — SQLite, inline CSS, no Sidekiq/Redis; the DB-backed sweeper stays the runner.

See `ROADMAP.md` for phases and `TICKETS.md` for the work items.
