# -*- encoding: utf-8 -*-
# Confidential and proprietary trade secret material of Ribose, Inc.
# (c) 2013 Ribose, Inc. as unpublished work.
#

# Adds attr_accessors that mask and unmask an object's attributes
module Indigo::AttrMasked
  autoload :Version, 'attr_masked/version'

  require 'indigo/attr_masked/railtie' if defined?(Rails)
  def self.extended(base) # :nodoc:
    base.class_eval do

      # Only include instance methods during the Rake task!
      # include InstanceMethods
      attr_writer :attr_masked_options
      @attr_masked_options, @masked_attributes = {}, {}
    end
  end

  # Generates attr_accessors that mask and unmask attributes transparently
  #
  # Options (any other options you specify are passed to the maskor's mask and unmask methods)
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
  #   :key              => The maskion key. This option may not be required if you're using a custom maskor. If you pass
  #                        a symbol representing an instance method then the :key option will be replaced with the result of the
  #                        method before being passed to the maskor. Objects that respond to :call are evaluated as well (including procs).
  #                        Any other key types will be passed directly to the maskor.
  #
  #   :encode           => If set to true, attributes will be encoded as well as masked. This is useful if you're
  #                        planning on storing the masked attributes in a database. The default encoding is 'm' (base64),
  #                        however this can be overwritten by setting the :encode option to some other encoding string instead of
  #                        just 'true'. See http://www.ruby-doc.org/core/classes/Array.html#M002245 for more encoding directives.
  #                        Defaults to false unless you're using it with ActiveRecord, DataMapper, or Sequel.
  #
  #   :default_encoding => Defaults to 'm' (base64).
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
  #   :maskor        => The object to use for masking. Defaults to maskor.
  #
  #   :mask_method   => The mask method name to call on the <tt>:maskor</tt> object. Defaults to 'mask'.
  #
  #   :unmask_method   => The unmask method name to call on the <tt>:maskor</tt> object. Defaults to 'unmask'.
  #
  #   :if               => Attributes are only masked if this option evaluates to true. If you pass a symbol representing an instance
  #                        method then the result of the method will be evaluated. Any objects that respond to <tt>:call</tt> are evaluated as well.
  #                        Defaults to true.
  #
  #   :unless           => Attributes are only masked if this option evaluates to false. If you pass a symbol representing an instance
  #                        method then the result of the method will be evaluated. Any objects that respond to <tt>:call</tt> are evaluated as well.
  #                        Defaults to false.
  #
  #   :mode             => Selects maskion mode for attribute: choose <tt>:single_iv_and_salt</tt> for compatibility
  #                        with the old attr_masked API: the default IV and salt of the underlying maskor object
  #                        is used; <tt>:per_attribute_iv_and_salt</tt> uses a per-attribute IV and salt attribute and
  #                        is the recommended mode for new deployments.
  #                        Defaults to <tt>:single_iv_and_salt</tt>.
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
      :prefix           => 'masked_',
      :suffix           => '',
      :if               => true,
      :unless           => false,
      :encode           => false,
      :default_encoding => 'm',
      :marshal          => false,
      :marshaler        => Marshal,
      :dump_method      => 'dump',
      :load_method      => 'load',
      :maskor        => maskor,
      :mask_method   => 'mask',
      :unmask_method   => 'unmask',
      :mode             => :single_iv_and_salt
    }.merge!(attr_masked_options).merge!(attributes.last.is_a?(Hash) ? attributes.pop : {})

    options[:encode] = options[:default_encoding] if options[:encode] == true

    attributes.each do |attribute|
      masked_attribute_name = (options[:attribute] ? options[:attribute] : [options[:prefix], attribute, options[:suffix]].join).to_sym

      instance_methods_as_symbols = instance_methods.collect { |method| method.to_sym }
      attr_reader masked_attribute_name unless instance_methods_as_symbols.include?(masked_attribute_name)
      attr_writer masked_attribute_name unless instance_methods_as_symbols.include?(:"#{masked_attribute_name}=")

      if options[:mode] == :per_attribute_iv_and_salt
        attr_reader (masked_attribute_name.to_s + "_iv").to_sym unless instance_methods_as_symbols.include?((masked_attribute_name.to_s + "_iv").to_sym )
        attr_writer (masked_attribute_name.to_s + "_iv").to_sym unless instance_methods_as_symbols.include?((masked_attribute_name.to_s + "_iv").to_sym )

        attr_reader (masked_attribute_name.to_s + "_salt").to_sym unless instance_methods_as_symbols.include?((masked_attribute_name.to_s + "_salt").to_sym )
        attr_writer (masked_attribute_name.to_s + "_salt").to_sym unless instance_methods_as_symbols.include?((masked_attribute_name.to_s + "_salt").to_sym )
      end

      define_method(attribute) do
        if options[:mode] == :per_attribute_iv_and_salt
          load_iv_for_attribute(attribute,masked_attribute_name, options[:algorithm])
          load_salt_for_attribute(attribute,masked_attribute_name)
        end

        instance_variable_get("@#{attribute}") || instance_variable_set("@#{attribute}", unmask(attribute, send(masked_attribute_name)))
      end

      define_method("#{attribute}=") do |value|
        if options[:mode] == :per_attribute_iv_and_salt
          load_iv_for_attribute(attribute, masked_attribute_name, options[:algorithm])
          load_salt_for_attribute(attribute, masked_attribute_name)
        end

        send("#{masked_attribute_name}=", mask(attribute, value))
        instance_variable_set("@#{attribute}", value)
      end

      define_method("#{attribute}?") do
        value = send(attribute)
        value.respond_to?(:empty?) ? !value.empty? : !!value
      end

      masked_attributes[attribute.to_sym] = options.merge(:attribute => masked_attribute_name)
    end
  end
  alias_method :attr_maskor, :attr_masked

  # Default options to use with calls to <tt>attr_masked</tt>
  #
  # It will inherit existing options from its superclass
  def attr_masked_options
    @attr_masked_options ||= superclass.attr_masked_options.dup
  end

  # Checks if an attribute is configured with <tt>attr_masked</tt>
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

  # unmasks a value for the attribute specified
  #
  # Example
  #
  #   class User
  #     attr_masked :email
  #   end
  #
  #   email = User.unmask(:email, 'SOME_masked_EMAIL_STRING')
  def unmask(attribute, masked_value, options = {})
    options = masked_attributes[attribute.to_sym].merge(options)
    if options[:if] && !options[:unless] && !masked_value.nil? && !(masked_value.is_a?(String) && masked_value.empty?)
      masked_value = masked_value.unpack(options[:encode]).first if options[:encode]
      value = options[:maskor].send(options[:unmask_method], options.merge!(:value => masked_value))
      if options[:marshal]
        value = options[:marshaler].send(options[:load_method], value)
      elsif defined?(Encoding)
        encoding = Encoding.default_internal || Encoding.default_external
        value = value.force_encoding(encoding.name)
      end
      value
    else
      masked_value
    end
  end

  # masks a value for the attribute specified
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
    if options[:if] && !options[:unless] && !value.nil? && !(value.is_a?(String) && value.empty?)
      value = options[:marshal] ? options[:marshaler].send(options[:dump_method], value) : value.to_s
      masked_value = options[:maskor].send(options[:mask_method], options.merge!(:value => value))
      masked_value = [masked_value].pack(options[:encode]) if options[:encode]
      masked_value
    else
      value
    end
  end

  # Contains a hash of masked attributes with virtual attribute names as keys
  # and their corresponding options as values
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

  # Forwards calls to :mask_#{attribute} or :unmask_#{attribute} to the corresponding mask or unmask method
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
    if method.to_s =~ /^((en|de)crypt)_(.+)$/ && attr_masked?($3)
      send($1, $3, *arguments)
    else
      super
    end
  end

  module InstanceMethods
    # unmasks a value for the attribute specified using options evaluated in the current object's scope
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
    #  @user.unmask(:email, 'SOME_masked_EMAIL_STRING')
    def unmask(attribute, masked_value)
      self.class.unmask(attribute, masked_value, evaluated_attr_masked_options_for(attribute))
    end

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
    def mask(attribute, value)
      self.class.mask(attribute, value, evaluated_attr_masked_options_for(attribute))
    end

    protected

      # Returns attr_masked options evaluated in the current object's scope for the attribute specified
      def evaluated_attr_masked_options_for(attribute)
        self.class.masked_attributes[attribute.to_sym].inject({}) { |hash, (option, value)| hash.merge!(option => evaluate_attr_masked_option(value)) }
      end

      # Evaluates symbol (method reference) or proc (responds to call) options
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

      def load_iv_for_attribute (attribute, masked_attribute_name, algorithm)
        iv = send("#{masked_attribute_name.to_s + "_iv"}")
          if(iv == nil)
            begin
              algorithm = algorithm || "aes-256-cbc"
              algo = OpenSSL::Cipher::Cipher.new(algorithm)
              iv = [algo.random_iv].pack("m")
              send("#{masked_attribute_name.to_s + "_iv"}=", iv)
            rescue RuntimeError
            end
          end
        self.class.masked_attributes[attribute.to_sym] = self.class.masked_attributes[attribute.to_sym].merge(:iv => iv.unpack("m").first) if (iv && !iv.empty?)
      end

      def load_salt_for_attribute(attribute, masked_attribute_name)
        salt = send("#{masked_attribute_name.to_s + "_salt"}") || send("#{masked_attribute_name.to_s + "_salt"}=", Digest::SHA256.hexdigest((Time.now.to_i * rand(1000)).to_s)[0..15])
        self.class.masked_attributes[attribute.to_sym] = self.class.masked_attributes[attribute.to_sym].merge(:salt => salt)
      end
  end
end

Object.extend Indigo::AttrMasked
