# (c) 2017 Ribose Inc.
#

# Adds attr_accessors that mask an object's attributes
module AttrMasker
  autoload :Version, "attr_masker/version"
  autoload :Attribute, "attr_masker/attribute"

  autoload :Error, "attr_masker/error"
  autoload :Performer, "attr_masker/performer"

  module Maskers
    autoload :Replacing, "attr_masker/maskers/replacing"
    autoload :SIMPLE, "attr_masker/maskers/simple"
  end

  require "attr_masker/railtie" if defined?(Rails)
  def self.extended(base) # :nodoc:
    base.class_eval do

      # Only include the dangerous instance methods during the Rake task!
      include InstanceMethods
      attr_writer :attr_masker_options
      @attr_masker_options, @masker_attributes = {}, {}
    end
  end

  # Generates attr_accessors that mask attributes transparently
  #
  # Options (any other options you specify are passed to the masker's mask
  # methods)
  #
  #   :marshal          => If set to true, attributes will be marshaled as well as masker. This is useful if you're planning
  #                        on masking something other than a string. Defaults to false unless you're using it with ActiveRecord
  #                        or DataMapper.
  #
  #   :marshaler        => The object to use for marshaling. Defaults to Marshal.
  #
  #   :dump_method      => The dump method name to call on the <tt>:marshaler</tt> object to. Defaults to 'dump'.
  #
  #   :load_method      => The load method name to call on the <tt>:marshaler</tt> object. Defaults to 'load'.
  #
  #   :masker           => The object to use for masking. It must respond to +#mask+. Defaults to AttrMasker::Maskers::Simple.
  #
  #   :if               => Attributes are only masker if this option evaluates to true. If you pass a symbol representing an instance
  #                        method then the result of the method will be evaluated. Any objects that respond to <tt>:call</tt> are evaluated as well.
  #                        Defaults to true.
  #
  #   :unless           => Attributes are only masker if this option evaluates to false. If you pass a symbol representing an instance
  #                        method then the result of the method will be evaluated. Any objects that respond to <tt>:call</tt> are evaluated as well.
  #                        Defaults to false.
  #
  # You can specify your own default options
  #
  #   class User
  #     # now all attributes will be encoded and marshaled by default
  #     attr_masker_options.merge!(:marshal => true, :some_other_option => true)
  #     attr_masker :configuration
  #   end
  #
  #
  # Example
  #
  #   class User
  #     attr_masker :email, :credit_card
  #     attr_masker :configuration, :marshal => true
  #   end
  #
  #   @user = User.new
  #   @user.masker_email # nil
  #   @user.email? # false
  #   @user.email = 'test@example.com'
  #   @user.email? # true
  #   @user.masker_email # returns the masker version of 'test@example.com'
  #
  #   @user.configuration = { :time_zone => 'UTC' }
  #   @user.masker_configuration # returns the masker version of configuration
  #
  #   See README for more examples
  def attr_masker(*attributes)
    options = {
      :if               => true,
      :unless           => false,
      :column_name      => nil,
      :marshal          => false,
      :marshaler        => Marshal,
      :dump_method      => "dump",
      :load_method      => "load",
      :masker           => AttrMasker::Maskers::SIMPLE,
    }.merge!(attr_masker_options).merge!(attributes.last.is_a?(Hash) ? attributes.pop : {})

    attributes.each do |attribute|
      masker_attributes[attribute.to_sym] = Attribute.new(attribute, self, options)
    end
  end

  # Default options to use with calls to <tt>attr_masker</tt>
  # XXX:Keep
  #
  # It will inherit existing options from its superclass
  def attr_masker_options
    @attr_masker_options ||= superclass.attr_masker_options.dup
  end

  # Checks if an attribute is configured with <tt>attr_masker</tt>
  # XXX:Keep
  #
  # Example
  #
  #   class User
  #     attr_accessor :name
  #     attr_masker :email
  #   end
  #
  #   User.attr_masker?(:name)  # false
  #   User.attr_masker?(:email) # true
  def attr_masker?(attribute)
    masker_attributes.has_key?(attribute.to_sym)
  end

  # masks a value for the attribute specified
  # XXX:modify
  #
  # Example
  #
  #   class User
  #     attr_masker :email
  #   end
  #
  #   masker_email = User.mask(:email, 'test@example.com')
  def mask(attribute, value, options = {})
    attribute = masker_attributes[attribute.to_sym]
    options = attribute.options.merge(options)
    # if options[:if] && !options[:unless] && !value.nil? && !(value.is_a?(String) && value.empty?)
    if options[:if] && !options[:unless]
      value = options[:marshal] ? options[:marshaler].send(options[:load_method], value) : value
      masker_value = options[:masker].call(options.merge!(value: value))
      options[:marshal] ? options[:marshaler].send(options[:dump_method], masker_value) : masker_value
    else
      value
    end
  end

  # Contains a hash of masker attributes with virtual attribute names as keys
  # and their corresponding options as values
  # XXX:Keep
  #
  # Example
  #
  #   class User
  #     attr_masker :email
  #   end
  #
  #   User.masker_attributes # { :email => { :attribute => 'masker_email' } }
  def masker_attributes
    @masker_attributes ||= superclass.masker_attributes.dup
  end

  # Forwards calls to :mask_#{attribute} to the corresponding mask method
  # if attribute was configured with attr_masker
  #
  # Example
  #
  #   class User
  #     attr_masker :email
  #   end
  #
  #   User.mask_email('SOME_masker_EMAIL_STRING')
  def method_missing(method, *arguments, &block)
    if method.to_s =~ /^mask_(.+)$/ && attr_masker?($1)
      send(:mask, $1, *arguments)
    else
      super
    end
  end

  module InstanceMethods

    # masks a value for the attribute specified using options evaluated in the current object's scope
    #
    # Example
    #
    #  class User
    #    attr_accessor :secret_key
    #    attr_masker :email
    #
    #    def initialize(secret_key)
    #      self.secret_key = secret_key
    #    end
    #  end
    #
    #  @user = User.new('some-secret-key')
    #  @user.mask(:email, 'test@example.com')
    def mask(attribute, value=nil)
      value = self.send(attribute) if value.nil?
      self.class.mask(attribute, value, evaluated_attr_masker_options_for(attribute))
    end

    protected

      # Returns attr_masker options evaluated in the current object's scope for the attribute specified
      # XXX:Keep
      def evaluated_attr_masker_options_for(attribute_name)
        attribute = self.class.masker_attributes[attribute_name.to_sym]
        attribute.options.inject({}) do |hash, (option, value)|
          if %i[if unless].include?(option)
            hash.merge!(option => evaluate_attr_masker_option(value))
          else
            hash.merge!(option => value)
          end
        end
      end

      # Evaluates symbol (method reference) or proc (responds to call) options
      # XXX:Keep
      #
      # If the option is not a symbol or proc then the original option is returned
      def evaluate_attr_masker_option(option)
        if option.is_a?(Symbol) && respond_to?(option)
          send(option)
        elsif option.respond_to?(:call)
          option.call(self)
        else
          option
        end
      end
  end
end

Object.extend AttrMasker
