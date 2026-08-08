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

  # Malformed new_values makes Apply raise (JSON::ParserError) when it parses
  # the change — a real transient failure, without stubbing the container.
  def schedule_broken(apply_at:)
    changes.create(
      target_type: "MenuItem", target_id: item.id,
      new_values: "not-json", apply_at: apply_at
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

  it "leaves the applied row unlocked" do
    change = schedule(400, apply_at: Time.now - 60)

    operation.call

    reloaded = changes.find(change.id)
    expect(reloaded.status).to eq("applied")
    expect(reloaded.locked_at).to be_nil
    expect(reloaded.locked_by).to be_nil
  end

  it "skips rows already claimed by another worker" do
    change = schedule(400, apply_at: Time.now - 60)
    changes.claim(change.id, worker: "other-worker", now: Time.now)

    result = operation.call

    expect(result).to be_success(0)
    expect(items.find(item.id).price_cents).to eq(350)
    expect(changes.find(change.id).locked_by).to eq("other-worker")
  end

  it "a second run applies nothing already claimed by a still-running first worker" do
    change1 = schedule(400, apply_at: Time.now - 60)
    change2 = schedule(410, apply_at: Time.now - 30)
    now = Time.now
    # Simulate a first worker mid-flight: it claimed both rows but hasn't applied yet.
    changes.claim(change1.id, worker: "worker-1", now: now)
    changes.claim(change2.id, worker: "worker-1", now: now)

    second_count = operation.call(now: now, worker: "worker-2")

    expect(second_count).to be_success(0)
    expect(items.find(item.id).price_cents).to eq(350)
  end

  it "records a failure, backs off, and unlocks the row when apply raises" do
    change = schedule_broken(apply_at: Time.now - 60)

    result = operation.call

    expect(result).to be_success(0)
    reloaded = changes.find(change.id)
    expect(reloaded.status).to eq("pending")
    expect(reloaded.attempts).to eq(1)
    expect(reloaded.last_error).not_to be_nil
    expect(reloaded.next_run_at).not_to be_nil
    expect(reloaded.locked_at).to be_nil
    expect(reloaded.locked_by).to be_nil
  end

  it "marks a row failed after max attempts and stops retrying it" do
    change = schedule_broken(apply_at: Time.now - 60)

    now = Time.now
    5.times do |i|
      operation.call(now: now)
      now += (2**(i + 1)) + 1
    end

    reloaded = changes.find(change.id)
    expect(reloaded.status).to eq("failed")
    expect(reloaded.attempts).to eq(5)
  end
end
