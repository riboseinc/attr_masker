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

    # Evaluates the +:if+ and +:unless+ attribute options on given instance.
    # Returns +true+ or +fasle+, depending on whether the attribute should be
    # masked for this object or not.
    def should_mask?(model_instance)
      not (
        options.key?(:if) && !evaluate_option(:if, model_instance) ||
        options.key?(:unless) && evaluate_option(:unless, model_instance)
      )
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

    def marshal_data(data)
      return data unless options[:marshal]
      options[:marshaler].send(options[:dump_method], data)
    end

    def unmarshal_data(data)
      return data unless options[:marshal]
      options[:marshaler].send(options[:load_method], data)
    end

    def column_name
      options[:column_name] || name
    end
  end
end
