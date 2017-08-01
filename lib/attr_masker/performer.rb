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
      end

      private

      def mask_class(klass)
        progressbar_for_model(klass) do |bar|
          klass.all.each do |model|
            mask_object model
            bar.increment
          end
        end
      end

      # For each masker attribute, mask it, and save it!
      #
      def mask_object(instance)
        klass = instance.class

        updates = klass.masker_attributes.reduce({}) do |acc, masker_attr|
          attr_name = masker_attr[0]
          column_name = masker_attr[1][:column_name] || attr_name
          masker_value = instance.mask(attr_name)
          acc.merge!(column_name => masker_value)
        end

        klass.all.update(instance.id, updates)
      end

      def progressbar_for_model(klass)
        bar = ProgressBar.create(
          title: klass.name,
          total: klass.count,
          throttle_rate: 0.1,
          format: %q[%t %c/%C (%j%%) %B %E],
        )

        yield bar
      ensure
        bar.finish
      end

      def all_models
        ::ActiveRecord::Base.descendants.select(&:table_exists?)
      end
    end
  end
end
