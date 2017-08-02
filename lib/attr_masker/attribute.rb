# (c) 2017 Ribose Inc.
#

module AttrMasker
  # Holds the definition of maskable attribute.
  class Attribute
    attr_reader :name, :model, :options

    def initialize(name, model, options)
      @name = name.to_sym
      @model = model
      @options = options
    end

    def column_name
      options[:column_name] || name
    end
  end
end
