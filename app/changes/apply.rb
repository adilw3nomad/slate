# frozen_string_literal: true

module Slate
  module Changes
    # Apply a pending change: merge its new_values onto the target record and
    # mark it applied. Shared by manual publishing and the scheduled sweeper.
    class Apply < Slate::Operation
      include Deps["repos.scheduled_change_repo", "repos.menu_item_repo", "contracts.change_contract"]

      # Polymorphic dispatch: target_type => injected repo. Register another
      # editable model here (and inject its repo above) to opt it in.
      REPOS = {"MenuItem" => :menu_item_repo}.freeze

      def call(change)
        repo = step target_repo(change.target_type)

        attrs = Slate::ChangeSet.from_json(change.new_values).symbolized
        step revalidate(change, attrs)

        updated = repo.update(change.target_id, attrs)
        scheduled_change_repo.mark_applied(change.id)

        updated
      end

      private

      def target_repo(target_type)
        method = REPOS[target_type]
        method ? Success(public_send(method)) : Failure(:unknown_target_type)
      end

      def revalidate(change, attrs)
        result = change_contract.call(attrs)
        return Success(attrs) if result.success?

        error = result.errors.to_h
        scheduled_change_repo.mark_failed(change.id, error.to_s)
        Failure(error)
      end
    end
  end
end
