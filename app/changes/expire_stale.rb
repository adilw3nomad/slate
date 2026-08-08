# frozen_string_literal: true

module Slate
  module Changes
    # Expire every pending change whose expires_at has passed instead of
    # letting it apply late. Run before ApplyDue in the sweeper.
    class ExpireStale < Slate::Operation
      include Deps["repos.scheduled_change_repo"]

      def call(now: Time.now)
        stale = scheduled_change_repo.expirable(now)
        stale.each { |change| scheduled_change_repo.mark_expired(change.id) }
        stale.length
      end
    end
  end
end
