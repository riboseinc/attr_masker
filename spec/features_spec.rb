# (c) 2017 Ribose Inc.
#

require "spec_helper"

RSpec.describe "Attr Masker gem" do
  example "The Rake task doesn't raise any exceptions" do
    expect { run_rake_task }.not_to raise_exception
  end

  def run_rake_task
    Rake::Task["db:mask"].invoke
  end
end
