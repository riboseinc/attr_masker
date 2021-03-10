# (c) 2017 Ribose Inc.
#

require "spec_helper"

RSpec.describe "db:mask", :suppress_progressbar do
  subject { Rake::Task["db:mask"] }

  let(:config_file_path) do
    File.expand_path("../dummy/config/attr_masker.rb", __dir__)
  end

  it "loads all application's models eagerly" do
    expect(Rails.application).to receive(:eager_load!)
    subject.execute
    expect(defined? NonPersistedModel).to be_truthy
  end

  it "loads configuration file if it exists", :force_config_file_reload do
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(config_file_path).and_return(true)
    expect { subject.execute }.to change { $CONFIG_LOADED_AT }
  end

  it "works without configuration file", :force_config_file_reload do
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(config_file_path).and_return(false)
    expect { subject.execute }.not_to change { $CONFIG_LOADED_AT }
  end
end
