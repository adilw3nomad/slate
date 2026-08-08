# frozen_string_literal: true

require "open3"

# Runs the real bin/sweep script as a subprocess (as cron/launchd would) and
# checks it records a sweep_runs row around the sweep. Tagged :js so
# spec/support/db/cleaning.rb uses truncation instead of a transaction —
# the subprocess needs to see (and commit) data outside this example's own
# connection.
RSpec.describe "bin/sweep", :db, :js do
  let(:items) { Hanami.app["repos.menu_item_repo"] }
  let(:changes) { Hanami.app["repos.scheduled_change_repo"] }
  let(:sweep_runs) { Hanami.app["repos.sweep_run_repo"] }

  it "records a sweep_runs row with timestamps and the applied count" do
    item = items.create(name: "Latte", price_cents: 350)
    changes.create(target_type: "MenuItem", target_id: item.id,
                   new_values: %({"price_cents":400}), apply_at: Time.now - 60)

    _out, status = Open3.capture2({"HANAMI_ENV" => "test"}, "bin/sweep", chdir: Hanami.app.root.to_s)

    expect(status).to be_success
    run = sweep_runs.recent(1).first
    expect(run).not_to be_nil
    expect(run.started_at).not_to be_nil
    expect(run.finished_at).not_to be_nil
    expect(run.applied_count).to eq(1)
    expect(run.failed_count).to eq(0)
  end
end
