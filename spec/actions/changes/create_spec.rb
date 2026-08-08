# frozen_string_literal: true

require "json"

RSpec.describe "POST /items/:id/changes", :db, type: :request do
  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }
  let(:item) { items.create(name: "Latte", price_cents: 350, description: "Classic") }

  it "stages a draft for changed fields only" do
    post "/items/#{item.id}/changes",
         name: "Latte", description: "Classic", price: "4.00", available: "1"

    expect(last_response).to be_redirect
    pending = changes.pending
    expect(pending.length).to eq(1)
    expect(JSON.parse(pending.first.new_values)).to eq("price_cents" => 400)
    expect(pending.first.apply_at).to be_nil
  end

  it "stages a scheduled change when a date is given" do
    post "/items/#{item.id}/changes", price: "4.00", apply_at: "2999-01-01T09:00"

    expect(changes.pending.first.apply_at).not_to be_nil
  end

  it "redirects back to edit with an error when nothing changed" do
    post "/items/#{item.id}/changes",
         name: "Latte", description: "Classic", price: "3.50", available: "1"

    expect(last_response).to be_redirect
    expect(last_response.headers["Location"]).to include("/items/#{item.id}/edit")
    expect(changes.pending).to be_empty
  end
end
