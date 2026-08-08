# frozen_string_literal: true

module Slate
  module Views
    module Items
      class Edit < Slate::View
        expose :item
        expose :error
      end
    end
  end
end
