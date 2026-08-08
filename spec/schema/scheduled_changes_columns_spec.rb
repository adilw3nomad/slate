# frozen_string_literal: true

# SLATE-001: the scheduled_changes table carries every column later phases need,
# so those tickets add logic rather than migrations.
RSpec.describe "scheduled_changes extended schema", :db do
  let(:repo) { Hanami.app["repos.scheduled_change_repo"] }

  it "persists and reads back the extended columns" do
    now = Time.now
    change = repo.create(
      target_type: "MenuItem", target_id: 1, new_values: "{}",
      base_values: %({"price_cents":350}), expires_at: now + 3600,
      attempts: 0, last_error: nil, locked_at: nil, locked_by: nil,
      next_run_at: now, author_id: 7, applied_by: nil
    )

    found = repo.find(change.id)

    expect(found.base_values).to eq(%({"price_cents":350}))
    expect(found.expires_at).not_to be_nil
    expect(found.attempts).to eq(0)
    expect(found.next_run_at).not_to be_nil
    expect(found.author_id).to eq(7)
  end
end
