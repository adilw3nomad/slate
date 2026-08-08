# frozen_string_literal: true

# End-to-end: staging a scheduled change and letting the sweeper apply it,
# exercising Stage -> ChangeSet -> ApplyDue -> Apply -> repos together.
RSpec.describe "scheduled change sweep", :db do
  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:stage) { Hanami.app["changes.stage"] }
  let(:apply_due) { Hanami.app["changes.apply_due"] }

  it "applies a scheduled change once its time has passed" do
    item = items.create(name: "Mocha", price_cents: 400)

    stage.call(target: item, changes: {price_cents: 450}, apply_at: Time.now - 60)
    expect(items.find(item.id).price_cents).to eq(400) # not yet swept

    expect(apply_due.call).to be_success(1)
    expect(items.find(item.id).price_cents).to eq(450) # swept
  end
end
