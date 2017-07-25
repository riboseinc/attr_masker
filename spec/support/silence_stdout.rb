RSpec.configure do |config|
  config.before(:each, suppress_stdout: true) do
    allow(STDOUT).to receive(:write)
  end
end
