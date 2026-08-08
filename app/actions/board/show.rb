# frozen_string_literal: true

module Slate
  module Actions
    module Board
      class Show < Slate::Action
        include Deps["repos.menu_item_repo", "repos.scheduled_change_repo"]

        def handle(request, response)
          response[:items] = menu_item_repo.all
          response[:pending_ids] = scheduled_change_repo.pending.map(&:target_id)
        end
      end
    end
  end
end
