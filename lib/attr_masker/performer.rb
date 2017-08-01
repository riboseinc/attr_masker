# (c) 2017 Ribose Inc.
#
module AttrMasker
  module Performer
    class ActiveRecord
      def mask
        unless defined? ::ActiveRecord
          raise AttrMasker::Error, "ActiveRecord undefined. Nothing to do!"
        end

        # Do not want production environment to be masked!
        #
        if Rails.env.production?
          raise AttrMasker::Error, "Attempted to run in production environment."
        end

        all_models.each do |klass|
          next if klass.masker_attributes.empty?
          mask_class(klass)
        end
        puts "All done!"
      end

      private

      def mask_class(klass)
        printf "Masking #{klass}... "
        if klass.count < 1
          puts "Nothing to do!"
        else
          klass.all.each { |model| mask_object model }
          puts " ==> done!"
        end
      end

      # For each masker attribute, mask it, and save it!
      #
      def mask_object(instance)
        printf "\n --> masking #{instance.id} - #{instance}... "

        klass = instance.class

        updates = klass.masker_attributes.reduce({}) do |acc, masker_attr|
          attr_name = masker_attr[0]
          column_name = masker_attr[1][:column_name] || attr_name
          masker_value = instance.mask(attr_name)
          acc.merge!(column_name => masker_value)
        end

        klass.all.update(instance.id, updates)

        printf "OK"
      end

      def all_models
        ::ActiveRecord::Base.descendants.select(&:table_exists?)
      end
    end
  end
end
