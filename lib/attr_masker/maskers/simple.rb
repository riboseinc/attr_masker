# (c) 2017 Ribose Inc.
#

module AttrMasker
  module Maskers
    # +Simple+ masker replaces values with a predefined +(redacted)+ string.
    # This is a default masker, which is used when no specific +:masker+ is
    # passed in +attr_masker+ method call.
    #
    # @example Would mask "Adam West" as "(redacted)"
    #   class User < ActiveRecord::Base
    #     m = AttrMasker::Maskers::Simple.new
    #     attr_masker :name, :masker => m
    #   end
    #
    # @example Would mask "Adam West" as "(redacted)"
    #   class User < ActiveRecord::Base
    #     attr_masker :name
    #   end
    class Simple
      # Accepts any keyword arguments, but they all are ignored.
      def call(**_opts)
        "(redacted)"
      end
    end
  end
end
