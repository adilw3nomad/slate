# frozen_string_literal: true

module Slate
  module Views
    module Board
      class Show < Slate::View
        expose :items
        expose :pending_ids
      end
    end
  end
end
