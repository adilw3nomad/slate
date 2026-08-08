# frozen_string_literal: true

module Slate
  module Relations
    class ScheduledChanges < Slate::DB::Relation
      schema :scheduled_changes, infer: true
    end
  end
end
