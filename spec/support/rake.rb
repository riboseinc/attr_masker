# (c) 2017 Ribose Inc.
#

require "rake"
Rails.application.load_tasks
load File.expand_path("../../lib/tasks/db.rake", __dir__)
