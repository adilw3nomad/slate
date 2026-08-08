# frozen_string_literal: true

RSpec.describe Slate::Changes::ReapStuck, :db do
  subject(:operation) { Hanami.app["changes.reap_stuck"] }

  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }

  def stage(status: "pending")
    changes.create(
      target_type: "MenuItem", target_id: 1,
      new_values: %({"price_cents":400}), apply_at: Time.now - 60, status:
    )
  end

  it "clears the lock on pending rows stuck locked past the timeout" do
    change = stage
    changes.claim(change.id, worker: "worker-1", now: Time.now - 3600)

    result = operation.call(now: Time.now, timeout_seconds: 600)

    expect(result).to be_success(1)
    reloaded = changes.find(change.id)
    expect(reloaded.locked_at).to be_nil
    expect(reloaded.locked_by).to be_nil
    expect(reloaded.status).to eq("pending")
  end

  it "leaves recently-locked rows alone" do
    change = stage
    changes.claim(change.id, worker: "worker-1", now: Time.now)

    result = operation.call(now: Time.now, timeout_seconds: 600)

    expect(result).to be_success(0)
    expect(changes.find(change.id).locked_by).to eq("worker-1")
  end

  it "returns the number of rows reaped" do
    change1 = stage
    change2 = stage
    changes.claim(change1.id, worker: "worker-1", now: Time.now - 3600)
    changes.claim(change2.id, worker: "worker-2", now: Time.now - 3600)

    expect(operation.call(now: Time.now, timeout_seconds: 600)).to be_success(2)
  end
end
