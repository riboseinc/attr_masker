# (c) 2017 Ribose Inc.
#

require "spec_helper"

RSpec.describe "db:mask", :suppress_progressbar do
  subject { Rake::Task["db:mask"] }

  it "loads all application's models eagerly" do
    expect(Rails.application).to receive(:eager_load!)
    subject.execute
    expect(defined? NonPersistedModel).to be_truthy
  end
end
