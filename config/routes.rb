# frozen_string_literal: true

module Slate
  class Routes < Hanami::Routes
    root to: "board.show"

    get "/items/:id/edit", to: "items.edit"
    post "/items/:id/changes", to: "changes.create"

    get "/changes", to: "changes.index"
    post "/changes/:id/publish", to: "changes.publish"
    post "/changes/:id/cancel", to: "changes.cancel"
  end
end
