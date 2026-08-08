# frozen_string_literal: true

RSpec.describe Slate::Changes::ExpireStale, :db do
  subject(:operation) { Hanami.app["changes.expire_stale"] }

  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }
  let(:item) { items.create(name: "Latte", price_cents: 350) }

  def schedule(price_cents, expires_at:)
    changes.create(
      target_type: "MenuItem", target_id: item.id,
      new_values: %({"price_cents":#{price_cents}}), apply_at: nil, expires_at: expires_at
    )
  end

  it "expires pending changes past their expires_at instead of applying them" do
    change = schedule(400, expires_at: Time.now - 60)

    operation.call

    expect(changes.find(change.id).status).to eq("expired")
    expect(items.find(item.id).price_cents).to eq(350)
  end

  it "leaves changes with a nil expires_at unaffected" do
    change = schedule(400, expires_at: nil)

    operation.call

    expect(changes.find(change.id).status).to eq("pending")
  end

  it "leaves changes not yet past their expires_at unaffected" do
    change = schedule(400, expires_at: Time.now + 3600)

    operation.call

    expect(changes.find(change.id).status).to eq("pending")
  end

  it "returns the number of changes expired" do
    schedule(400, expires_at: Time.now - 60)
    schedule(410, expires_at: Time.now - 30)
    schedule(999, expires_at: Time.now + 3600)

    expect(operation.call).to be_success(2)
  end
end
