# (c) 2017 Ribose Inc.
#
module AttrMasker
  module Maskers
    # +Replacing+ masker replaces every character of string which is being
    # masked with +replacement+ one, preserving the length of the masked string
    # (provided that a replacement string contains a single character, which is
    # a typical case). Optionally, non-alphanumeric characters like dashes or
    # spaces may be left unchanged.
    #
    # @example Would mask "Adam West" as "XXXXXXXXX"
    #   class User < ActiveRecord::Base
    #     m = AttrMasker::Maskers::Replacing.new(replacement: "X")
    #     attr_masker :name, :masker => m
    #   end
    #
    # @example Would mask "123-456-789" as "XXX-XXX-XXX"
    #   class User < ActiveRecord::Base
    #     m = AttrMasker::Maskers::Replacing.new(
    #         replacement: "X", alphanum_only: true)
    #     attr_masker :phone, :masker => m
    #   end
    class Replacing
      attr_reader :replacement, :alphanum_only

      # @param replacement [String] replacement string
      # @param alphanum_only [Boolean] whether to leave non-alphanumeric
      #   characters unchanged or not
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
