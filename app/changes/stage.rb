# frozen_string_literal: true

module Slate
  module Changes
    # Stage a proposed change to a target record. With no apply_at it's a draft
    # (published by hand); with an apply_at it's scheduled (applied by the sweeper).
    class Stage < Slate::Operation
      include Deps["repos.scheduled_change_repo", "contracts.change_contract"]

      def call(target:, changes:, apply_at: nil)
        attrs = step validate(changes)

        scheduled_change_repo.create(
          target_type: target.class.name.split("::").last,
          target_id: target.id,
          new_values: Slate::ChangeSet.new(attrs).to_json,
          apply_at: apply_at
        )
      end

      private

      def validate(changes)
        result = change_contract.call(changes)
        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end
    end
  end
end
