# -*- encoding: utf-8 -*-
# Confidential and proprietary trade secret material of Ribose, Inc.
# (c) 2013 Ribose, Inc. as unpublished work.
#

# URL: 
# http://blog.nathanhumbert.com/2010/02/rails-3-loading-rake-tasks-from-gem.html

require 'indigo/attr_masked'
require 'rails'

module Indigo::AttrMasked
  class Railtie < Rails::Railtie
    railtie_name :attr_masked

    rake_tasks do
      load 'tasks/db.rake'
    end
  end
end
