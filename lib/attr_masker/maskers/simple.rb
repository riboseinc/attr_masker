module AttrMasker
  module Maskers
    # This default masker simply replaces any value with a fixed string.
    #
    # +opts+ is a Hash with the key :value that gives you the current attribute
    # value.
    #
    class Simple

      def self.call opts
        "(redacted)"
      end
    end
  end
end
