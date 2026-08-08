# frozen_string_literal: true

RSpec.describe Slate::ChangeSet do
  it "round-trips through JSON" do
    set = Slate::ChangeSet.new(price_cents: 400, name: "Latte")

    restored = Slate::ChangeSet.from_json(set.to_json)

    expect(restored).to eq(set)
  end

  it "stores attributes with string keys" do
    set = Slate::ChangeSet.new(price_cents: 400)

    expect(set.attributes).to eq("price_cents" => 400)
  end

  it "exposes symbol keys for persistence" do
    set = Slate::ChangeSet.new("price_cents" => 400)

    expect(set.symbolized).to eq(price_cents: 400)
  end

  it "applies its changes over a base record's attributes" do
    base = {name: "Latte", price_cents: 350, available: true}
    set = Slate::ChangeSet.new(price_cents: 400)

    expect(set.apply_to(base)).to eq(name: "Latte", price_cents: 400, available: true)
  end

  it "does not mutate the base attributes" do
    base = {price_cents: 350}
    Slate::ChangeSet.new(price_cents: 400).apply_to(base)

    expect(base).to eq(price_cents: 350)
  end
end
