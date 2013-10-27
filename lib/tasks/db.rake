# -*- encoding: utf-8 -*-
# Confidential and proprietary trade secret material of Ribose, Inc.
# (c) 2013 Ribose, Inc. as unpublished work.
#

namespace :db do
  desc 'Mask every DB record according to rules set up in the respective ActiveRecord'

  # If just:
  #   task :mask do ... end,
  # then connection won't be established.  Will need the '=> :environment'.
  #
  # URL: 
  # http://stackoverflow.com/questions/14163938/activerecordconnectionnotestablished-within-a-rake-task
  task :mask => :environment do

    unless Kernel.const_defined? :ActiveRecord
      warn 'ActiveRecord undefined. Nothing to do!'
      exit 1
    end

    # Send the #mask! message to each and every record that has persistence in 
    # the DB.
    #
    ActiveRecord::Base.descendants.each do |klass|
      if klass.table_exists?

        # include mixin
        klass.class_eval do
          include Indigo::AttrMasked::InstanceMethods
        end

        printf "Masking #{klass}... "

        klass.each do |model|
          model.mask!
        end
        printf "done\n"
      end
    end
  end
end
