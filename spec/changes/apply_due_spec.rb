# frozen_string_literal: true

RSpec.describe Slate::Changes::ApplyDue, :db do
  subject(:operation) { Hanami.app["changes.apply_due"] }

  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }
  let(:item) { items.create(name: "Latte", price_cents: 350) }

  def schedule(price_cents, apply_at:)
    changes.create(
      target_type: "MenuItem", target_id: item.id,
      new_values: %({"price_cents":#{price_cents}}), apply_at: apply_at
    )
  end

  it "applies past-due changes" do
    schedule(400, apply_at: Time.now - 60)

    operation.call

    expect(items.find(item.id).price_cents).to eq(400)
  end

  it "does not apply future-dated changes" do
    schedule(999, apply_at: Time.now + 3600)

    operation.call

    expect(items.find(item.id).price_cents).to eq(350)
  end

  it "returns the number of changes applied" do
    schedule(400, apply_at: Time.now - 60)
    schedule(410, apply_at: Time.now - 30)
    schedule(999, apply_at: Time.now + 3600)

    expect(operation.call).to be_success(2)
  end
end
