# frozen_string_literal: true

RSpec.describe Slate::Repos::MenuItemRepo, :db do
  subject(:repo) { Hanami.app["repos.menu_item_repo"] }

  it "creates and finds a menu item" do
    created = repo.create(name: "Flat White", description: "Silky", price_cents: 350)

    found = repo.find(created.id)

    expect(found.name).to eq("Flat White")
    expect(found.price_cents).to eq(350)
    expect(found.available).to be(true)
  end

  it "updates an existing item's attributes" do
    item = repo.create(name: "Latte", price_cents: 350)

    repo.update(item.id, price_cents: 400, description: "Now bigger")

    reloaded = repo.find(item.id)
    expect(reloaded.price_cents).to eq(400)
    expect(reloaded.description).to eq("Now bigger")
  end

  it "lists all items" do
    repo.create(name: "Espresso", price_cents: 250)
    repo.create(name: "Cortado", price_cents: 320)

    expect(repo.all.map(&:name)).to contain_exactly("Espresso", "Cortado")
  end
end
