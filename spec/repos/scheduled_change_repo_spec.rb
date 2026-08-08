# frozen_string_literal: true

RSpec.describe Slate::Repos::ScheduledChangeRepo, :db do
  subject(:repo) { Hanami.app["repos.scheduled_change_repo"] }

  def stage(apply_at:, status: "pending")
    repo.create(
      target_type: "MenuItem", target_id: 1,
      new_values: %({"price_cents":400}), apply_at:, status:
    )
  end

  it "creates a pending change with a default status" do
    change = repo.create(
      target_type: "MenuItem", target_id: 7, new_values: %({"name":"X"}), apply_at: nil
    )

    found = repo.find(change.id)
    expect(found.target_type).to eq("MenuItem")
    expect(found.status).to eq("pending")
    expect(found.apply_at).to be_nil
  end

  describe "#due" do
    it "returns pending changes whose apply_at is in the past" do
      past = stage(apply_at: Time.now - 3600)

      due = repo.due(Time.now)

      expect(due.map(&:id)).to eq([past.id])
    end

    it "ignores future-dated changes" do
      stage(apply_at: Time.now + 3600)

      expect(repo.due(Time.now)).to be_empty
    end

    it "ignores drafts (no apply_at)" do
      stage(apply_at: nil)

      expect(repo.due(Time.now)).to be_empty
    end

    it "ignores already-applied changes" do
      stage(apply_at: Time.now - 3600, status: "applied")

      expect(repo.due(Time.now)).to be_empty
    end

    it "ignores rows whose next_run_at (retry backoff) is still in the future" do
      change = stage(apply_at: Time.now - 3600)
      repo.record_failure(change.id, error: "boom", now: Time.now)

      expect(repo.due(Time.now)).to be_empty
    end

    it "includes rows once their next_run_at has passed" do
      change = stage(apply_at: Time.now - 3600)
      repo.record_failure(change.id, error: "boom", now: Time.now - 3600)

      expect(repo.due(Time.now).map(&:id)).to eq([change.id])
    end
  end

  describe "#claim" do
    it "succeeds and stamps locked_by/locked_at when the row is unclaimed" do
      change = stage(apply_at: Time.now - 60)

      claimed = repo.claim(change.id, worker: "worker-1", now: Time.now)

      expect(claimed).to be true
      reloaded = repo.find(change.id)
      expect(reloaded.locked_by).to eq("worker-1")
      expect(reloaded.locked_at).not_to be_nil
    end

    it "fails when the row is already claimed by another worker" do
      change = stage(apply_at: Time.now - 60)
      repo.claim(change.id, worker: "worker-1", now: Time.now)

      claimed = repo.claim(change.id, worker: "worker-2", now: Time.now)

      expect(claimed).to be false
      expect(repo.find(change.id).locked_by).to eq("worker-1")
    end

    it "fails when the row is not pending" do
      change = stage(apply_at: Time.now - 60, status: "applied")

      expect(repo.claim(change.id, worker: "worker-1", now: Time.now)).to be false
    end

    it "succeeds again once a previous lock has gone stale" do
      change = stage(apply_at: Time.now - 60)
      repo.claim(change.id, worker: "worker-1", now: Time.now - 3600)

      claimed = repo.claim(change.id, worker: "worker-2", now: Time.now)

      expect(claimed).to be true
      expect(repo.find(change.id).locked_by).to eq("worker-2")
    end
  end

  describe "#record_failure" do
    it "increments attempts, records the error, sets next_run_at with backoff, and unlocks the row" do
      change = stage(apply_at: Time.now - 60)
      repo.claim(change.id, worker: "worker-1", now: Time.now)
      now = Time.now

      repo.record_failure(change.id, error: "boom", now: now)

      reloaded = repo.find(change.id)
      expect(reloaded.attempts).to eq(1)
      expect(reloaded.last_error).to eq("boom")
      expect(reloaded.next_run_at).to be_within(1).of(now + 2)
      expect(reloaded.locked_at).to be_nil
      expect(reloaded.locked_by).to be_nil
      expect(reloaded.status).to eq("pending")
    end

    it "marks the row failed once max_attempts is reached" do
      change = stage(apply_at: Time.now - 60)

      4.times { repo.record_failure(change.id, error: "boom", now: Time.now, max_attempts: 5) }
      reloaded = repo.find(change.id)
      expect(reloaded.status).to eq("pending")

      repo.record_failure(change.id, error: "boom", now: Time.now, max_attempts: 5)

      reloaded = repo.find(change.id)
      expect(reloaded.status).to eq("failed")
      expect(reloaded.attempts).to eq(5)
    end
  end

  describe "#unlock_stuck" do
    it "clears the lock on pending rows locked before the given time" do
      change = stage(apply_at: Time.now - 60)
      repo.claim(change.id, worker: "worker-1", now: Time.now - 3600)

      count = repo.unlock_stuck(before: Time.now - 600)

      expect(count).to eq(1)
      reloaded = repo.find(change.id)
      expect(reloaded.locked_at).to be_nil
      expect(reloaded.locked_by).to be_nil
    end

    it "does not touch locks newer than the cutoff" do
      change = stage(apply_at: Time.now - 60)
      repo.claim(change.id, worker: "worker-1", now: Time.now)

      count = repo.unlock_stuck(before: Time.now - 600)

      expect(count).to eq(0)
      expect(repo.find(change.id).locked_by).to eq("worker-1")
    end

    it "does not touch rows that are not pending" do
      change = stage(apply_at: Time.now - 60, status: "applied")

      count = repo.unlock_stuck(before: Time.now)

      expect(count).to eq(0)
    end
  end

  describe "#mark_applied" do
    it "flips status to applied and stamps applied_at, only while pending" do
      change = stage(apply_at: Time.now - 60)

      repo.mark_applied(change.id)

      reloaded = repo.find(change.id)
      expect(reloaded.status).to eq("applied")
      expect(reloaded.applied_at).not_to be_nil
    end
  end

  describe "#expirable" do
    def stage_with_expiry(expires_at:, status: "pending")
      repo.create(
        target_type: "MenuItem", target_id: 1,
        new_values: %({"price_cents":400}), apply_at: nil, expires_at:, status:
      )
    end

    it "returns pending changes whose expires_at is in the past" do
      expired = stage_with_expiry(expires_at: Time.now - 3600)

      expect(repo.expirable(Time.now).map(&:id)).to eq([expired.id])
    end

    it "ignores changes with a nil expires_at" do
      stage_with_expiry(expires_at: nil)

      expect(repo.expirable(Time.now)).to be_empty
    end

    it "ignores changes not yet past their expires_at" do
      stage_with_expiry(expires_at: Time.now + 3600)

      expect(repo.expirable(Time.now)).to be_empty
    end

    it "ignores changes that are no longer pending" do
      stage_with_expiry(expires_at: Time.now - 3600, status: "applied")

      expect(repo.expirable(Time.now)).to be_empty
    end
  end

  describe "#mark_expired" do
    it "flips status to expired, only while pending" do
      change = repo.create(
        target_type: "MenuItem", target_id: 1,
        new_values: %({"price_cents":400}), apply_at: nil, expires_at: Time.now - 60
      )

      repo.mark_expired(change.id)

      expect(repo.find(change.id).status).to eq("expired")
    end
  end
end
