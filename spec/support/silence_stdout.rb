RSpec.configure do |config|
  config.before(:each, suppress_progressbar: true) do
    stub_const(
      "::ProgressBar::Output::DEFAULT_OUTPUT_STREAM",
      StringIO.new,
    )
  end
end
