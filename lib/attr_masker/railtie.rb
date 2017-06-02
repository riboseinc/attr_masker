# -*- encoding: utf-8 -*-
# (c) 2017 Ribose Inc.
#

# URL: 
# http://blog.nathanhumbert.com/2010/02/rails-3-loading-rake-tasks-from-gem.html

require 'attr_masker'
require 'rails'

module AttrMasker
  class Railtie < Rails::Railtie
    railtie_name :attr_masker

    rake_tasks do
      load 'tasks/db.rake'
    end
  end
end
