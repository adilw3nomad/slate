# frozen_string_literal: true

module Slate
  module Actions
    module Runs
      class Index < Slate::Action
        include Deps["repos.sweep_run_repo"]

        def handle(request, response)
          response[:runs] = sweep_run_repo.recent(20)
        end
      end
    end
  end
end
