# -*- encoding: utf-8 -*-
# Confidential and proprietary trade secret material of Ribose, Inc.
# (c) 2013 Ribose, Inc. as unpublished work.
#

module Indigo
  module AttrMasked
    # Contains information about this gem's version
    module Version
      MAJOR = 0
      MINOR = 1
      PATCH = 0

      # Returns a version string by joining <tt>MAJOR</tt>, <tt>MINOR</tt>, and <tt>PATCH</tt> with <tt>'.'</tt>
      #
      # Example
      #
      #   Version.string # '1.0.2'
      def self.string
        [MAJOR, MINOR, PATCH].join('.')
      end
    end
  end
end
