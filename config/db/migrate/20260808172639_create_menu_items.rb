# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :menu_items do
      primary_key :id
      column :name, String, null: false
      column :description, String
      column :price_cents, Integer, null: false, default: 0
      column :available, TrueClass, null: false, default: true
      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end
  end
end
