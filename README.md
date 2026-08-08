# Slate

A lean [Hanami](https://hanamirb.org) app demonstrating **scheduled / draft changes**
to editable models, built test-first (TDD) with a DDD layering. The domain is a café
**menu board**: staged edits are held off to the side and either published by hand
(a *draft*) or applied automatically at a set time (a *scheduled* change) by a
**database-backed sweeper** — no Sidekiq, no Redis.

> **Note:** this is a practice project for learning [Hanami](https://hanamirb.org)
> (relations, repos, operations, actions/views, the DB layer). It's a learning
> sandbox, not a production library.

## Concepts

- **MenuItem** — the editable aggregate (name, description, price, availability).
- **Change** — a proposed set of attribute changes to a MenuItem.
  - no `apply_at` → **draft** (you publish it)
  - an `apply_at` → **scheduled** (the sweeper applies it when due)
- One polymorphic `scheduled_changes` table + a dispatch map (`Changes::Apply`) means
  the mechanism generalises to *any* editable model — shown here with one.

## Layout

```
lib/slate/            Money, ChangeSet          — pure domain value objects
app/relations/        ROM relations             — schema
app/repos/            repositories              — persistence boundary
app/contracts/        ChangeContract            — dry-validation
app/changes/          Stage, Apply, ApplyDue    — application operations (dry-operation)
app/actions/ + views/ + templates/              — web (server-rendered, inline CSS)
bin/sweep             the DB-backed job runner
```

## Setup

```bash
bundle install
bundle exec hanami db prepare   # creates SQLite db, migrates, seeds demo data
```

## Run

```bash
bundle exec hanami server       # http://localhost:2300
```

- **/** — the menu board (items with a staged change show a *Pending* badge)
- **/items/:id/edit** — stage a change; leave the time empty for a draft, set it to schedule; live preview
- **/changes** — pending changes grouped Drafts / Scheduled, with before→after diffs and Publish / Cancel

## The sweeper (scheduled changes)

`bin/sweep` applies every pending change whose `apply_at` has passed.

```bash
bin/sweep            # run once
bin/sweep --watch    # run every 10s (Ctrl+C to stop)
bin/sweep --watch 30 # every 30s
```

In production you'd invoke `bin/sweep` from cron / launchd / systemd on a short interval.

## Demo script

1. `bundle exec hanami db prepare && bundle exec hanami server`
2. Open **/changes** — a draft (Cortado) and a scheduled change (Pumpkin Spice) are seeded.
3. Publish the draft → the board reflects the new price immediately.
4. On the board, **Edit** any item, change the price, and set *Apply at* a minute in the
   future → it appears under *Scheduled*.
5. Run `bin/sweep` after that time → the change applies and drops off the pending list.

## Tests

```bash
bundle exec rspec
```

Domain value objects, repositories, each operation, an end-to-end sweep, and every web
action are covered.
