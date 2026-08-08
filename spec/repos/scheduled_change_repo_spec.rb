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
