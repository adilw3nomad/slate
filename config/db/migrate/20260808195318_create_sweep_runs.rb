# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :sweep_runs do
      primary_key :id
      column :started_at, DateTime, null: false
      column :finished_at, DateTime
      column :applied_count, Integer, null: false, default: 0
      column :failed_count, Integer, null: false, default: 0
    end
  end
end
