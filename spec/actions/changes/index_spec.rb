# frozen_string_literal: true

RSpec.describe "GET /changes", :db, type: :request do
  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }

  it "shows a pending change with a before/after price diff" do
    item = items.create(name: "Latte", price_cents: 350)
    changes.create(target_type: "MenuItem", target_id: item.id,
                   new_values: %({"price_cents":400}), apply_at: nil)

    get "/changes"

    expect(last_response).to be_ok
    expect(last_response.body).to include("Latte")
    expect(last_response.body).to include("£3.50") # before
    expect(last_response.body).to include("£4.00") # after
  end

  it "does not list applied changes" do
    item = items.create(name: "Latte", price_cents: 350)
    changes.create(target_type: "MenuItem", target_id: item.id,
                   new_values: %({"price_cents":400}), apply_at: nil, status: "applied")

    get "/changes"

    expect(last_response.body).not_to include("£4.00")
  end
end
