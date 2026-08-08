# frozen_string_literal: true

module Slate
  module Changes
    # The sweeper's core: apply every pending change whose apply_at has passed.
    # Driven by bin/sweep (cron/launchd) — our DB-backed job runner, no Redis.
    class ApplyDue < Slate::Operation
      include Deps["repos.scheduled_change_repo", "changes.apply"]

      def call(now: Time.now)
        due = scheduled_change_repo.due(now)
        due.each { |change| apply.call(change) }
        due.length
      end
    end
  end
end
