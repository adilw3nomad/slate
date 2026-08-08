# frozen_string_literal: true

RSpec.describe "POST /changes/:id/cancel", :db, type: :request do
  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }

  it "cancels a pending change without touching the item" do
    item = items.create(name: "Latte", price_cents: 350)
    change = changes.create(target_type: "MenuItem", target_id: item.id,
                            new_values: %({"price_cents":400}), apply_at: nil)

    post "/changes/#{change.id}/cancel"

    expect(last_response).to be_redirect
    expect(changes.find(change.id).status).to eq("cancelled")
    expect(items.find(item.id).price_cents).to eq(350)
  end
end
