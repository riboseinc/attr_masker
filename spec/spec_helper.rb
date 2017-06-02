# -*- encoding: utf-8 -*-
# (c) 2017 Ribose Inc.
#

require 'rails/all'

Dir["#{File.dirname(__FILE__)}/helpers/**/*.rb"].each do |path|
  require path
end

RSpec.configure do |config|
  config.color_enabled = true
end
