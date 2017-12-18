# (c) 2017 Ribose Inc.
#

# rubocop:disable Rails/SkipsModelValidations

module AttrMasker
  module Performer
    class Base
      def mask
        # Do not want production environment to be masked!
        #
        if Rails.env.production?
          unless ENV['FORCE_MASK']
            msg = 'Attempted to run in production environment.'
            raise AttrMasker::Error, msg
          end
        end

        all_models.each do |klass|
          next if klass.masker_attributes.empty?
          mask_class(klass)
        end
      end

      private

      def mask_class(klass)
        progressbar_for_model(klass) do |bar|
          klass.all.unscoped.each do |model|
            mask_object model
            bar.increment
          end
        end
      end

      # For each masker attribute, mask it, and save it!
      #
      def mask_object(instance)
        klass = instance.class

        updates = klass.masker_attributes.values.reduce({}) do |acc, attribute|
          next acc unless attribute.should_mask?(instance)

          attribute.mask(instance)
          acc.merge! attribute.masked_attributes_new_values(instance)
        end

        make_update instance, updates unless updates.empty?
      end

      def progressbar_for_model(klass)
        bar = ProgressBar.create(
          title: klass.name,
          total: klass.unscoped.count,
          throttle_rate: 0.1,
          format: %q[%t %c/%C (%j%%) %B %E]
        )

        yield bar
      ensure
        bar.finish
      end
    end

    class ActiveRecord < Base
      def dependencies_available?
        defined? ::ActiveRecord
      end

      def all_models
        ::ActiveRecord::Base.descendants.select(&:table_exists?)
      end

      def make_update(instance, updates)
        instance.class.all.unscoped.where(id: instance.id).update_all(updates)
      end
    end

    class Mongoid < Base
      def dependencies_available?
        defined? ::Mongoid
      end

      def all_models
        ::Mongoid.models
      end

      def make_update(instance, updates)
        instance.class.all.unscoped.where(id: instance.id).update(updates)
      end
    end
  end
end
