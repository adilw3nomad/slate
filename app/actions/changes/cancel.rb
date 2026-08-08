# frozen_string_literal: true

module Slate
  module Actions
    module Changes
      class Cancel < Slate::Action
        include Deps["repos.scheduled_change_repo"]

        def handle(request, response)
          scheduled_change_repo.mark_cancelled(request.params[:id])
          response.redirect_to "/changes"
        end
      end
    end
  end
end
