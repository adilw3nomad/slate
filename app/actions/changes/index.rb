# frozen_string_literal: true

module Slate
  module Actions
    module Changes
      class Index < Slate::Action
        include Deps["repos.scheduled_change_repo", "repos.menu_item_repo"]

        def handle(request, response)
          response[:changes] = scheduled_change_repo.pending.map { |change| present(change) }
        end

        private

        # Build a view-ready row: the target's name, draft/scheduled flag, and a
        # before/after diff for each changed field.
        def present(change)
          item = menu_item_repo.find(change.target_id)
          set = Slate::ChangeSet.from_json(change.new_values)

          {
            id: change.id,
            item_name: item.name,
            draft: change.apply_at.nil?,
            apply_at: change.apply_at,
            diffs: set.attributes.map { |field, after|
              {field: field, before: item.public_send(field), after: after}
            }
          }
        end
      end
    end
  end
end
