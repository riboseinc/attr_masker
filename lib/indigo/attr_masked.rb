# -*- encoding: utf-8 -*-
# Confidential and proprietary trade secret material of Ribose, Inc.
# (c) 2013 Ribose, Inc. as unpublished work.
#

# Adds attr_accessors that mask an object's attributes
module Indigo::AttrMasked
  autoload :Version, 'attr_masked/version'

  require 'indigo/attr_masked/railtie' if defined?(Rails)
  def self.extended(base) # :nodoc:
    base.class_eval do

      # Only include the dangerous instance methods during the Rake task!
      include InstanceMethods
      attr_writer :attr_masked_options
      @attr_masked_options, @masked_attributes = {}, {}
    end
  end

  # Generates attr_accessors that mask attributes transparently
  #
  # Options (any other options you specify are passed to the masker's mask 
  # methods)
  #
  #   :attribute        => The name of the referenced masked attribute. For example
  #                        <tt>attr_accessor :email, :attribute => :ee</tt> would generate an
  #                        attribute named 'ee' to store the masked email. This is useful when defining
  #                        one attribute to mask at a time or when the :prefix and :suffix options
  #                        aren't enough. Defaults to nil.
  #
  #   :prefix           => A prefix used to generate the name of the referenced masked attributes.
  #                        For example <tt>attr_accessor :email, :password, :prefix => 'crypted_'</tt> would
  #                        generate attributes named 'crypted_email' and 'crypted_password' to store the
  #                        masked email and password. Defaults to 'masked_'.
  #
  #   :suffix           => A suffix used to generate the name of the referenced masked attributes.
  #                        For example <tt>attr_accessor :email, :password, :prefix => '', :suffix => '_masked'</tt>
  #                        would generate attributes named 'email_masked' and 'password_masked' to store the
  #                        masked email. Defaults to ''.
  #
  #   :key              => The maskion key. This option may not be required if you're using a custom masker. If you pass
  #                        a symbol representing an instance method then the :key option will be replaced with the result of the
  #                        method before being passed to the masker. Objects that respond to :call are evaluated as well (including procs).
  #                        Any other key types will be passed directly to the masker.
  #
  #   :encode           => If set to true, attributes will be encoded as well as masked. This is useful if you're
  #                        planning on storing the masked attributes in a database. The default encoding is 'm' (base64),
  #                        however this can be overwritten by setting the :encode option to some other encoding string instead of
  #                        just 'true'. See http://www.ruby-doc.org/core/classes/Array.html#M002245 for more encoding directives.
  #                        Defaults to false unless you're using it with ActiveRecord, DataMapper, or Sequel.
  #
  #   :marshal          => If set to true, attributes will be marshaled as well as masked. This is useful if you're planning
  #                        on masking something other than a string. Defaults to false unless you're using it with ActiveRecord
  #                        or DataMapper.
  #
  #   :marshaler        => The object to use for marshaling. Defaults to Marshal.
  #
  #   :dump_method      => The dump method name to call on the <tt>:marshaler</tt> object to. Defaults to 'dump'.
  #
  #   :load_method      => The load method name to call on the <tt>:marshaler</tt> object. Defaults to 'load'.
  #
  #   :masker        => The object to use for masking. Defaults to Masker.
  #
  #   :mask_method   => The mask method name to call on the <tt>:masker</tt> object. Defaults to 'mask'.
  #
  #   :if               => Attributes are only masked if this option evaluates to true. If you pass a symbol representing an instance
  #                        method then the result of the method will be evaluated. Any objects that respond to <tt>:call</tt> are evaluated as well.
  #                        Defaults to true.
  #
  #   :unless           => Attributes are only masked if this option evaluates to false. If you pass a symbol representing an instance
  #                        method then the result of the method will be evaluated. Any objects that respond to <tt>:call</tt> are evaluated as well.
  #                        Defaults to false.
  #
  # You can specify your own default options
  #
  #   class User
  #     # now all attributes will be encoded and marshaled by default
  #     attr_masked_options.merge!(:encode => true, :marshal => true, :some_other_option => true)
  #     attr_masked :configuration, :key => 'my secret key'
  #   end
  #
  #
  # Example
  #
  #   class User
  #     attr_masked :email, :credit_card, :key => 'some secret key'
  #     attr_masked :configuration, :key => 'some other secret key', :marshal => true
  #   end
  #
  #   @user = User.new
  #   @user.masked_email # nil
  #   @user.email? # false
  #   @user.email = 'test@example.com'
  #   @user.email? # true
  #   @user.masked_email # returns the masked version of 'test@example.com'
  #
  #   @user.configuration = { :time_zone => 'UTC' }
  #   @user.masked_configuration # returns the masked version of configuration
  #
  #   See README for more examples
  def attr_masked(*attributes)
    options = {
      :if               => true,
      :unless           => false,
      :encode           => false,
      :marshal          => false,
      :marshaler        => Marshal,
      :dump_method      => 'dump',
      :load_method      => 'load',
      :masker           => Indigo::AttrMasked::Masker,
      :mask_method      => 'mask',
    }.merge!(attr_masked_options).merge!(attributes.last.is_a?(Hash) ? attributes.pop : {})

    attributes.each do |attribute|
      masked_attribute_name = (options[:attribute] ? options[:attribute] : [options[:prefix], attribute, options[:suffix]].join).to_sym

      instance_methods_as_symbols = instance_methods.collect { |method| method.to_sym }
      attr_reader masked_attribute_name unless instance_methods_as_symbols.include?(masked_attribute_name)
      attr_writer masked_attribute_name unless instance_methods_as_symbols.include?(:"#{masked_attribute_name}=")

      # define_method(attribute) do
      #   instance_variable_get("@#{attribute}") ||
      #     instance_variable_set("@#{attribute}", unmask(attribute, send(masked_attribute_name)))
      # end

      # define_method("#{attribute}=") do |value|
      #   send("#{masked_attribute_name}=", mask(attribute, value))
      #   instance_variable_set("@#{attribute}", value)
      # end

      # define_method("#{attribute}?") do
      #   value = send(attribute)
      #   value.respond_to?(:empty?) ? !value.empty? : !!value
      # end

      masked_attributes[attribute.to_sym] = options.merge(:attribute => masked_attribute_name)
    end
  end

  # Default options to use with calls to <tt>attr_masked</tt>
  # XXX:Keep
  #
  # It will inherit existing options from its superclass
  def attr_masked_options
    @attr_masked_options ||= superclass.attr_masked_options.dup
  end

  # Checks if an attribute is configured with <tt>attr_masked</tt>
  # XXX:Keep
  #
  # Example
  #
  #   class User
  #     attr_accessor :name
  #     attr_masked :email
  #   end
  #
  #   User.attr_masked?(:name)  # false
  #   User.attr_masked?(:email) # true
  def attr_masked?(attribute)
    masked_attributes.has_key?(attribute.to_sym)
  end

  # masks a value for the attribute specified
  # XXX:modify
  #
  # Example
  #
  #   class User
  #     attr_masked :email
  #   end
  #
  #   masked_email = User.mask(:email, 'test@example.com')
  def mask(attribute, value, options = {})
    options = masked_attributes[attribute.to_sym].merge(options)
    # if options[:if] && !options[:unless] && !value.nil? && !(value.is_a?(String) && value.empty?)
    if options[:if] && !options[:unless]
      value = options[:marshal] ? options[:marshaler].send(options[:dump_method], value) : value.to_s
      # masked_value = options[:masker].send(options[:mask_method], options.merge!(:value => value))
      masked_value = options[:masker].send(options[:mask_method], options.merge!(:value => value))
      masked_value
    else
      value
    end
  end

  # Contains a hash of masked attributes with virtual attribute names as keys
  # and their corresponding options as values
  # XXX:Keep
  #
  # Example
  #
  #   class User
  #     attr_masked :email, :key => 'my secret key'
  #   end
  #
  #   User.masked_attributes # { :email => { :attribute => 'masked_email', :key => 'my secret key' } }
  def masked_attributes
    @masked_attributes ||= superclass.masked_attributes.dup
  end

  # Forwards calls to :mask_#{attribute} to the corresponding mask method
  # if attribute was configured with attr_masked
  #
  # Example
  #
  #   class User
  #     attr_masked :email, :key => 'my secret key'
  #   end
  #
  #   User.mask_email('SOME_masked_EMAIL_STRING')
  def method_missing(method, *arguments, &block)
    if method.to_s =~ /^mask_(.+)$/ && attr_masked?($1)
      send(:mask, $1, *arguments)
    else
      super
    end
  end

  class Masker

    # This default masker simply replaces any value with a fixed string.
    #
    # +opts+ is a Hash with the key :value that gives you the current attribute 
    # value.
    #
    def self.mask opts
      '(redacted)'
    end
  end

  # Only include these methods in the rake task, and only run it in QA, cuz 
  # they're DANGEROUS!
  #
  module DangerousInstanceMethods

    # For each masked attribute, mask it, and save it!
    #
    def mask!
      return if self.class.masked_attributes.length < 1

      sql_snippet = self.class.masked_attributes.map do |masked_attr|
        masked_attr[0]
      end.inject({}) do |acc, attr_name|

        # build a map of { attr_name => masked_value }
        masked_value = self.mask(attr_name)
        acc.merge(
          attr_name => masked_value
        )
      end.inject([]) do |acc, (attr_name, masked_value)|
        acc << "#{attr_name}=#{ActiveRecord::Base.sanitize(masked_value)}"
      end.join(', ')

      sql = <<-EOQ
        UPDATE #{self.class.table_name} SET #{sql_snippet} WHERE id=#{self.id}
      EOQ

      ActiveRecord::Base.connection.execute sql
    end
  end

  module InstanceMethods

    # masks a value for the attribute specified using options evaluated in the current object's scope
    #
    # Example
    #
    #  class User
    #    attr_accessor :secret_key
    #    attr_masked :email, :key => :secret_key
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
      self.class.mask(attribute, value, evaluated_attr_masked_options_for(attribute))
    end

    protected

      # Returns attr_masked options evaluated in the current object's scope for the attribute specified
      # XXX:Keep
      def evaluated_attr_masked_options_for(attribute)
        self.class.masked_attributes[attribute.to_sym].inject({}) do |hash, (option, value)|
          hash.merge!(option => evaluate_attr_masked_option(value))
        end
      end

      # Evaluates symbol (method reference) or proc (responds to call) options
      # XXX:Keep
      #
      # If the option is not a symbol or proc then the original option is returned
      def evaluate_attr_masked_option(option)
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

Object.extend Indigo::AttrMasked
