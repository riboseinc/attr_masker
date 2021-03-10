RSpec.configure do |config|
  config.before(:each, :force_config_file_reload) do
    config_path = Rails.root.join("config", "attr_masker.rb").to_s
    # $" holds names of source files which have been loaded already.
    # Removing a path from that list causes given file to be loaded
    # again at next #require call.
    $".delete(config_path)
  end
end
