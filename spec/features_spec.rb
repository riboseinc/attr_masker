# (c) 2017 Ribose Inc.
#

# No point in using ApplicationRecord here.
# rubocop:disable Rails/ApplicationRecord

require "spec_helper"

RSpec.describe "Attr Masker gem" do
  before do
    stub_const "User", Class.new(ActiveRecord::Base)
  end

  let!(:han) do
    User.create!(
      first_name: "Han",
      last_name: "Solo",
      email: "han@example.test",
    )
  end

  let!(:luke) do
    User.create!(
      first_name: "Luke",
      last_name: "Skywalker",
      email: "luke@jedi.example.test",
    )
  end

  example "Masking a single text attribute with default options" do
    User.class_eval do
      attr_masker :last_name
    end

    expect { run_rake_task }.not_to(change { User.count })

    expect { han.reload }.to(change { han.last_name }.to("(redacted)"))

    expect(1).to eq(1)
  end

  def run_rake_task
    Rake::Task["db:mask"].invoke
  end
end
