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

    # Mask the attribute on given model.  Masking will be performed regardless
    # of +:if+ and +:unless+ options.  A +should_mask?+ method should be called
    # separately to ensure that given object is eligible for masking.
    #
    # The method returns the masked value but does not modify the object's
    # attribute.
    #
    # If +marshal+ attribute's option is +true+, the attribute value will be
    # loaded before masking, and dumped to proper storage format prior
    # returning.
    def mask(model_instance)
      value = unmarshal_data(model_instance.send(name))
      masker_value = options[:masker].call(options.merge!(value: value))
      model_instance.send("#{name}=", marshal_data(masker_value))
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
