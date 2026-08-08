# frozen_string_literal: true

RSpec.describe Slate::Money do
  it "formats pounds and pence" do
    expect(Slate::Money.new(350).to_s).to eq("£3.50")
  end

  it "pads pence to two digits" do
    expect(Slate::Money.new(405).to_s).to eq("£4.05")
  end

  it "formats whole pounds with .00" do
    expect(Slate::Money.new(400).to_s).to eq("£4.00")
  end

  it "compares equal by value" do
    expect(Slate::Money.new(350)).to eq(Slate::Money.new(350))
  end
end
