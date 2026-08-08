# frozen_string_literal: true

module Slate
  module Changes
    # The sweeper's core: apply every pending change whose apply_at has passed.
    # Driven by bin/sweep (cron/launchd) — our DB-backed job runner, no Redis.
    class ApplyDue < Slate::Operation
      include Deps["repos.scheduled_change_repo", "changes.apply"]

      MAX_ATTEMPTS = 5

      def call(now: Time.now, worker: default_worker)
        due = scheduled_change_repo.due(now)

        due.count do |change|
          next false unless scheduled_change_repo.claim(change.id, worker: worker, now: now)

          begin
            apply.call(change)
            scheduled_change_repo.unlock(change.id)
            true
          rescue => e
            scheduled_change_repo.record_failure(change.id, error: e.message, now: now, max_attempts: MAX_ATTEMPTS)
            false
          end
        end
      end

      private

      def default_worker
        "sweep-#{Process.pid}"
      end
    end
  end
end
