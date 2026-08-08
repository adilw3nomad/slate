# frozen_string_literal: true

require "json"

RSpec.describe Slate::Changes::Stage, :db do
  subject(:operation) { Hanami.app["changes.stage"] }

  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:item) { items.create(name: "Latte", price_cents: 350) }

  it "stages a draft (no apply_at) as a pending change" do
    result = operation.call(target: item, changes: {price_cents: 400})

    expect(result).to be_success
    change = result.value!
    expect(change.status).to eq("pending")
    expect(change.apply_at).to be_nil
    expect(change.target_type).to eq("MenuItem")
    expect(change.target_id).to eq(item.id)
    expect(JSON.parse(change.new_values)).to eq("price_cents" => 400)
  end

  it "stages a scheduled change when given an apply_at" do
    result = operation.call(target: item, changes: {price_cents: 400}, apply_at: Time.now + 3600)

    expect(result).to be_success
    expect(result.value!.apply_at).not_to be_nil
  end

  it "fails when no changes are given" do
    result = operation.call(target: item, changes: {})

    expect(result).to be_failure
  end

  it "fails when price is negative" do
    result = operation.call(target: item, changes: {price_cents: -5})

    expect(result).to be_failure
  end
end
