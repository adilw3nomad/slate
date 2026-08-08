# Seeds a small café menu plus a couple of pending changes so the demo has
# something to show. Idempotent: it clears the tables first.

app = Hanami.app
items = app["repos.menu_item_repo"]
stage = app["changes.stage"]

# Clear existing rows (dev/demo only).
app["db.rom"].relations[:scheduled_changes].dataset.delete
app["db.rom"].relations[:menu_items].dataset.delete

menu = [
  {name: "Flat White",   description: "Double ristretto, steamed milk",     price_cents: 340, available: true},
  {name: "Filter Coffee", description: "Rotating single origin, batch brew", price_cents: 290, available: true},
  {name: "Cortado",       description: "Equal parts espresso and milk",      price_cents: 320, available: true},
  {name: "Cold Brew",     description: "18-hour steep, served over ice",     price_cents: 380, available: true},
  {name: "Mocha",         description: "Espresso, chocolate, steamed milk",  price_cents: 400, available: true},
  {name: "Pumpkin Spice", description: "Seasonal — back for autumn",         price_cents: 420, available: false}
]

created = menu.map { |attrs| items.create(**attrs) }
by_name = created.to_h { |i| [i.name, i] }

# A draft: a price tweak waiting for a human to publish.
stage.call(target: by_name.fetch("Cortado"), changes: {price_cents: 330})

# A scheduled change: the seasonal latte goes live next Monday 09:00.
next_monday = Time.now + ((8 - Time.now.wday) % 7 + 1) * 86_400
go_live = Time.new(next_monday.year, next_monday.month, next_monday.day, 9, 0, 0)
stage.call(
  target: by_name.fetch("Pumpkin Spice"),
  changes: {available: true, price_cents: 430},
  apply_at: go_live
)

puts "Seeded #{created.length} menu items + 2 pending changes."
