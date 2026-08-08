# frozen_string_literal: true

module Slate
  module Relations
    class MenuItems < Slate::DB::Relation
      schema :menu_items, infer: true
    end
  end
end
