module AttrMasker
  module Maskers
    # This default masker simply replaces any value with a fixed string.
    #
    # +opts+ is a Hash with the key :value that gives you the current attribute
    # value.
    #
    SIMPLE = lambda do |_opts|
      "(redacted)"
    end
  end
end
