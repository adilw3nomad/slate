# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :scheduled_changes do
      primary_key :id
      column :target_type, String, null: false
      column :target_id, Integer, null: false
      column :new_values, String, null: false # JSON-encoded attribute changes
      column :apply_at, DateTime              # nil = draft; set = scheduled
      column :status, String, null: false, default: "pending"
      column :created_at, DateTime, null: false
      column :applied_at, DateTime

      index %i[status apply_at]
    end
  end
end
