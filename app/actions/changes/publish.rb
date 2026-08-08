# frozen_string_literal: true

module Slate
  module Actions
    module Changes
      class Publish < Slate::Action
        include Deps["repos.scheduled_change_repo", "changes.apply"]

        def handle(request, response)
          change = scheduled_change_repo.find(request.params[:id])
          apply.call(change)
          response.redirect_to "/changes"
        end
      end
    end
  end
end
