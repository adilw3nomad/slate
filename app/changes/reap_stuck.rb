# frozen_string_literal: true

module Slate
  module Changes
    # Crash recovery: clears locks left behind by workers that claimed a row
    # and then died before applying (or unlocking) it, so it can be retried.
    class ReapStuck < Slate::Operation
      include Deps["repos.scheduled_change_repo"]

      def call(now: Time.now, timeout_seconds:)
        scheduled_change_repo.unlock_stuck(before: now - timeout_seconds)
      end
    end
  end
end
