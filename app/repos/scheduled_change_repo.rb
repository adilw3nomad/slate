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
      # excluded automatically since NULL <= now is never true.
      def due(now = Time.now)
        scheduled_changes.where(status: "pending").where { apply_at <= now }.to_a
      end

      # Atomic-ish claim: the update only touches rows still `pending`, so a
      # second worker (or a re-run) applying the same row is a no-op.
      def mark_applied(id, at: Time.now)
        scheduled_changes.by_pk(id).where(status: "pending")
          .changeset(:update, status: "applied", applied_at: at).commit
      end

      def mark_cancelled(id)
        scheduled_changes.by_pk(id).where(status: "pending")
          .changeset(:update, status: "cancelled").commit
      end
    end
  end
end
