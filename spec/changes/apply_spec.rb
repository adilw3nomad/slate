# frozen_string_literal: true

RSpec.describe Slate::Changes::Apply, :db do
  subject(:operation) { Hanami.app["changes.apply"] }

  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }
  let(:item) { items.create(name: "Latte", price_cents: 350) }

  def stage(new_values, apply_at: nil)
    changes.create(
      target_type: "MenuItem", target_id: item.id,
      new_values: new_values, apply_at: apply_at
    )
  end

  it "merges the change onto the target and marks it applied" do
    change = stage(%({"price_cents":400,"description":"Now bigger"}))

    result = operation.call(change)

    expect(result).to be_success
    reloaded = items.find(item.id)
    expect(reloaded.price_cents).to eq(400)
    expect(reloaded.description).to eq("Now bigger")
    expect(changes.find(change.id).status).to eq("applied")
  end

  it "leaves other attributes untouched" do
    change = stage(%({"price_cents":400}))

    operation.call(change)

    expect(items.find(item.id).name).to eq("Latte")
  end

  it "fails for an unknown target type" do
    change = changes.create(
      target_type: "Widget", target_id: 1, new_values: %({"x":1}), apply_at: nil
    )

    expect(operation.call(change)).to be_failure
  end

  it "re-validates staged attrs at apply time and rejects invalid ones without touching the target" do
    change = stage(%({"price_cents":-5}))

    result = operation.call(change)

    expect(result).to be_failure
    expect(items.find(item.id).price_cents).to eq(350)
    reloaded_change = changes.find(change.id)
    expect(reloaded_change.status).to eq("failed")
    expect(reloaded_change.last_error).not_to be_nil
  end
end
