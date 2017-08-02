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

    # Evaluates option (typically +:if+ or +:unless+) on given model instance.
    # That option can be either a proc (a model is passed as an only argument),
    # or a symbol (a method of that name is called on model instance).
    def evaluate_option(option_name, model_instance)
      option = options[option_name]

      if option.is_a?(Symbol)
        model_instance.send(option)
      elsif option.respond_to?(:call)
        option.call(model_instance)
      else
        option
      end
    end

    def column_name
      options[:column_name] || name
    end
  end
end
