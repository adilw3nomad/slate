# frozen_string_literal: true

RSpec.describe "GET /runs", :db, type: :request do
  let(:sweep_runs) { Hanami.app["repos.sweep_run_repo"] }

  it "lists recent sweep runs newest-first with timestamps and applied count" do
    sweep_runs.create(started_at: Time.now - 3600, finished_at: Time.now - 3599, applied_count: 7)
    sweep_runs.create(started_at: Time.now - 60, finished_at: Time.now - 59, applied_count: 42)

    get "/runs"

    expect(last_response).to be_ok
    counts = last_response.body.scan(/(\d+) applied/).flatten.map(&:to_i)
    expect(counts).to eq([42, 7])
  end

  it "shows an empty state when there are no runs" do
    get "/runs"

    expect(last_response).to be_ok
    expect(last_response.body).to include("No sweep runs")
  end
end
