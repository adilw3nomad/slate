# frozen_string_literal: true

module Slate
  module Repos
    class ScheduledChangeRepo < Slate::DB::Repo
      def create(attrs)
        scheduled_changes
          .changeset(:create, {created_at: Time.now, status: "pending"}.merge(attrs))
          .commit
      end

      def find(id)
        scheduled_changes.by_pk(id).one
      end

      def pending
        scheduled_changes.where(status: "pending").to_a
      end

      # Scheduled changes whose time has come. Drafts (apply_at IS NULL) are
      # excluded automatically since NULL <= now is never true. A row that
      # failed and is backing off is only due once its next_run_at has passed.
      def due(now = Time.now)
        scheduled_changes.where(status: "pending")
          .where { apply_at <= now }
          .where { next_run_at.is(nil) | (next_run_at <= now) }
          .to_a
      end

      # Atomic-ish claim: the update only touches rows still `pending`, so a
      # second worker (or a re-run) applying the same row is a no-op.
      def mark_applied(id, at: Time.now)
        scheduled_changes.by_pk(id).where(status: "pending")
          .changeset(:update, status: "applied", applied_at: at).commit
      end

      def mark_failed(id, error)
        scheduled_changes.by_pk(id).where(status: "pending")
          .changeset(:update, status: "failed", last_error: error).commit
      end

      def mark_cancelled(id)
        scheduled_changes.by_pk(id).where(status: "pending")
          .changeset(:update, status: "cancelled").commit
      end

      # Pending changes that expired before ever being applied.
      def expirable(now = Time.now)
        scheduled_changes.where(status: "pending").where { expires_at <= now }.to_a
      end

      def mark_expired(id)
        scheduled_changes.by_pk(id).where(status: "pending")
          .changeset(:update, status: "expired").commit
      end

      # A lock older than this is considered abandoned (worker crashed) and
      # may be reclaimed by another worker via #claim.
      STALE_LOCK_SECONDS = 300

      # Claims a pending row for `worker` so only one runner applies it. Only
      # succeeds if the row is unclaimed or its lock has gone stale. Returns
      # whether the claim succeeded.
      def claim(id, worker:, now: Time.now)
        stale_before = now - STALE_LOCK_SECONDS

        updated = scheduled_changes.by_pk(id)
          .where(status: "pending")
          .where { locked_at.is(nil) | (locked_at <= stale_before) }
          .changeset(:update, locked_at: now, locked_by: worker)
          .commit

        !updated.nil?
      end

      # Clears a row's lock so it can be claimed again.
      def unlock(id)
        scheduled_changes.by_pk(id)
          .changeset(:update, locked_at: nil, locked_by: nil)
          .commit
      end

      # Records a failed apply attempt: bumps attempts, stores the error,
      # schedules a backed-off retry via next_run_at, and unlocks the row.
      # Once attempts reaches max_attempts the row is marked "failed" and
      # stops being picked up by #due.
      def record_failure(id, error:, now: Time.now, max_attempts: 5)
        current = scheduled_changes.by_pk(id).one
        return nil unless current

        attempts = current.attempts + 1
        status = attempts >= max_attempts ? "failed" : "pending"

        scheduled_changes.by_pk(id)
          .changeset(:update,
            attempts: attempts,
            last_error: error,
            next_run_at: now + backoff(attempts),
            locked_at: nil,
            locked_by: nil,
            status: status)
          .commit
      end

      # Clears locks left behind by crashed workers: pending rows still
      # locked before the given cutoff. Returns the number of rows cleared.
      def unlock_stuck(before:)
        stuck = scheduled_changes.where(status: "pending")
          .where { locked_at.not(nil) & (locked_at <= before) }
          .to_a

        stuck.each { |row| unlock(row.id) }

        stuck.length
      end

      private

      def backoff(attempts)
        2**attempts
      end
    end
  end
end
