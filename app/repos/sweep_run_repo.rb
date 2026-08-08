# frozen_string_literal: true

module Slate
  module Repos
    class SweepRunRepo < Slate::DB::Repo
      def create(attrs)
        sweep_runs.changeset(:create, attrs).commit
      end

      # Newest-first, limited to `limit` rows.
      def recent(limit)
        sweep_runs.order(Sequel.desc(:started_at)).limit(limit).to_a
      end
    end
  end
end
