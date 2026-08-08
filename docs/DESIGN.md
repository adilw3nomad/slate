# Slate — design

A lean Hanami app demonstrating **scheduled / draft changes** to editable models,
built TDD + DDD. Domain: a café **menu board**.

## Ubiquitous language
- **MenuItem** — aggregate root: name, description, price (`Money` VO over `price_cents`), availability.
- **Change** — a proposed modification to a MenuItem's attributes.
  - no `apply_at` → **Draft** (a human publishes it)
  - has `apply_at` → **Scheduled** (the sweeper applies it when due)
  - lifecycle: `pending → applied` (or `cancelled`)
- **Applying** a Change merges its `new_values` onto the target. Publishing (draft) and
  the sweeper (scheduled) share one apply path.

## Layers (DDD)
- Domain (`app/domain/`): framework-free VOs — `Money`, `ChangeSet`.
- Application (`app/operations/`): `Changes::Stage`, `Changes::Apply`, `Changes::ApplyDue`.
- Infra: ROM relations (`app/relations/`) + repos (`app/repos/`).
- Validation (`app/contracts/`): dry-validation for staged attrs.
- Web (`app/actions/`, `app/views/`, `app/templates/`).
- Runner (`bin/sweep`): boots the app, runs `Changes::ApplyDue` — a DB-backed job runner
  (no Sidekiq/Redis). Atomic claim via SQLite's single-writer `UPDATE ... WHERE status='pending'`.

## Data model (SQLite)
```
menu_items:        id, name, description, price_cents, available, timestamps
scheduled_changes: id, target_type, target_id, new_values(JSON text), apply_at(nullable),
                   status('pending'), created_at, applied_at
```
`target_type/target_id` keep the design polymorphic (dispatch map in `Changes::Apply`),
so it generalises to any editable model — demonstrated with one (`MenuItem`).

## Change lifecycle
1. Edit an item → `Changes::Stage` validates + writes a `pending` Change (draft if no date).
2. Publish → `Changes::Apply` merges `new_values`, marks `applied`.
3. `bin/sweep` → `Changes::ApplyDue` applies `pending AND apply_at <= now`.

## UX (server-rendered, inline CSS, no build step)
1. **Board** — menu cards; items with a pending change show a badge.
2. **Item edit** — stage a change; date empty = draft, filled = scheduled; live preview.
3. **Pending changes** — publish / cancel, grouped draft vs scheduled.
