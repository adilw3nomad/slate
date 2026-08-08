# frozen_string_literal: true

RSpec.describe "GET /items/:id/edit", :db, type: :request do
  let(:items) { Hanami.app["repos.menu_item_repo"] }

  it "renders the edit form with the item's current values" do
    item = items.create(name: "Latte", price_cents: 350, description: "Classic")

    get "/items/#{item.id}/edit"

    expect(last_response).to be_ok
    expect(last_response.body).to include("Latte")
    expect(last_response.body).to include("3.50") # price in pounds, prefilled
  end

  it "returns 404 for an unknown item" do
    get "/items/999999/edit"

    expect(last_response.status).to eq(404)
  end
end
