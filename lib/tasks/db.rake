# (c) 2017 Ribose Inc.
#

namespace :db do
  desc "Mask every DB record according to rules set up in the respective " \
  "ActiveRecord"

  # If just:
  #   task :mask do ... end,
  # then connection won't be established.  Will need the '=> :environment'.
  #
  # URL:
  # http://stackoverflow.com/questions/14163938/activerecordconnectionnotestablished-within-a-rake-task
  #
  task :mask => :environment do
    Rails.application.eager_load!

    config_file = Rails.root.join("config", "attr_masker.rb").to_s
    require config_file if File.file?(config_file)

    performers = AttrMasker::Performer::Base.descendants.map(&:new)
    performers.select!(&:dependencies_available?)

    if performers.empty?
      raise AttrMasker::Error, "No supported database!"
    end

    performers.each(&:mask)
  end
end
