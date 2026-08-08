# frozen_string_literal: true

module Slate
  module Actions
    module Items
      class Edit < Slate::Action
        include Deps["repos.menu_item_repo"]

        def handle(request, response)
          item = menu_item_repo.find(request.params[:id])
          halt 404 unless item

          response[:item] = item
          response[:error] = request.params[:error]
        end
      end
    end
  end
end
