# (c) 2017 Ribose Inc.
#
module AttrMasker
  module Maskers
    # This default masker simply replaces any value with a fixed string.
    #
    # +opts+ is a Hash with the key :value that gives you the current attribute
    # value.
    #
    class Replacing
      attr_reader :replacement, :alphanum_only

      def initialize(replacement: "*", alphanum_only: false)
        replacement = "" if replacement.nil?
        @replacement = replacement
        @alphanum_only = alphanum_only
      end

      def call(value:, **_opts)
        return value unless value.is_a? String

        if alphanum_only
          value.gsub(/[[:alnum:]]/, replacement)
        else
          replacement * value.size
        end
      end
    end
  end
end
