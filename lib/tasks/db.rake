# (c) 2017 Ribose Inc.
#

# Hashrocket style looks better when describing task dependencies.
# rubocop:disable Style/HashSyntax

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
    AttrMasker::Performer::ActiveRecord.new.mask
  end
end
