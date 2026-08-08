# frozen_string_literal: true

RSpec.describe Slate::Repos::SweepRunRepo, :db do
  subject(:repo) { Hanami.app["repos.sweep_run_repo"] }

  describe "#create" do
    it "persists started_at, finished_at, applied_count, and failed_count" do
      started = Time.now - 5
      finished = Time.now

      run = repo.create(started_at: started, finished_at: finished, applied_count: 3, failed_count: 1)

      expect(run.started_at).not_to be_nil
      expect(run.finished_at).not_to be_nil
      expect(run.applied_count).to eq(3)
      expect(run.failed_count).to eq(1)
    end

    it "defaults failed_count to 0" do
      run = repo.create(started_at: Time.now, finished_at: Time.now, applied_count: 0)

      expect(run.failed_count).to eq(0)
    end
  end

  describe "#recent" do
    it "returns the newest runs first, limited to the given count" do
      older = repo.create(started_at: Time.now - 3600, finished_at: Time.now - 3599, applied_count: 1)
      newer = repo.create(started_at: Time.now - 60, finished_at: Time.now - 59, applied_count: 2)

      recent = repo.recent(1)

      expect(recent.map(&:id)).to eq([newer.id])
      expect(repo.recent(10).map(&:id)).to eq([newer.id, older.id])
    end
  end
end
