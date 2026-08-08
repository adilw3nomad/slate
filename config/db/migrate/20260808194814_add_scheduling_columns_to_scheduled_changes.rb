# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :scheduled_changes do
      add_column :base_values, String   # JSON snapshot of fields at stage time (conflict detection)
      add_column :expires_at, DateTime  # past this, a pending change expires instead of applying
      add_column :attempts, Integer, null: false, default: 0
      add_column :last_error, String
      add_column :locked_at, DateTime   # crash recovery: when a worker claimed the row
      add_column :locked_by, String
      add_column :next_run_at, DateTime # retry backoff: don't retry before this
      add_column :author_id, Integer    # who staged it
      add_column :applied_by, Integer   # who published it (nil for the sweeper)
    end
  end
end

