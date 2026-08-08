# frozen_string_literal: true

RSpec.describe "GET /", :db, type: :request do
  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }

  it "lists menu items with formatted prices" do
    items.create(name: "Flat White", price_cents: 350)

    get "/"

    expect(last_response).to be_ok
    expect(last_response.body).to include("Flat White")
    expect(last_response.body).to include("£3.50")
  end

  it "flags items that have a pending change" do
    item = items.create(name: "Latte", price_cents: 350)
    changes.create(target_type: "MenuItem", target_id: item.id,
                   new_values: %({"price_cents":400}), apply_at: nil)

    get "/"

    expect(last_response.body).to include("Pending")
  end
end
