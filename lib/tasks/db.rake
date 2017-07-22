# (c) 2017 Ribose Inc.
#

# Hashrocket style looks better when describing task dependencies.
# rubocop:disable Style/HashSyntax

namespace :db do
  desc 'Mask every DB record according to rules set up in the respective ActiveRecord'

  # If just:
  #   task :mask do ... end,
  # then connection won't be established.  Will need the '=> :environment'.
  #
  # URL:
  # http://stackoverflow.com/questions/14163938/activerecordconnectionnotestablished-within-a-rake-task
  #
  task :mask => :environment do
    unless Kernel.const_defined? :ActiveRecord
      warn 'ActiveRecord undefined. Nothing to do!'
      exit 1
    end

    # Do not want production environment to be masked!
    #
    if Rails.env.production?
      Rails.logger.warn "Why are you masking me?! :("
      exit 1
    end

    # Send the #mask! message to each and every record that has persistence in
    # the DB.
    #
    ActiveRecord::Base.descendants.each do |klass|
      if klass.table_exists?

        # include mixin for this class
        klass.class_eval do
          # extend AttrMasker::DangerousClassMethods
          include AttrMasker::DangerousInstanceMethods
        end

        printf "Masking #{klass}... "

        if klass.count < 1 || klass.masker_attributes.length < 1
          puts "Nothing to do!"
        else

          klass.all.each do |model|
            printf "\n --> masking #{model.id} - #{model}... "
            model.mask!
            printf "OK"
          end

          puts " ==> done!"
        end
      end
    end
    puts "All done!"
  end
end
