# (c) 2017 Ribose Inc.
#

module AttrMasker
  module Model
    def self.extended(base) # :nodoc:
      base.class_eval do
        attr_writer :attr_masker_options
        @attr_masker_options = {}
        @masker_attributes = {}
      end
    end

    # Generates attr_accessors that mask attributes transparently
    #
    # Options (any other options you specify are passed to the masker's mask
    # methods)
    #
    # [:masker]
    #     The object to use for masking. It must respond to +#mask+. Defaults to
    #     AttrMasker::Maskers::Simple.
    #
    # [:if]
    #     Attributes are only masker if this option evaluates to true. If you
    #     pass a symbol representing an instance method then the result of
    #     the method will be evaluated. Any objects that respond to
    #     <tt>:call</tt> are evaluated as well.  Defaults to true.
    #
    # [:unless]
    #     Attributes are only masker if this option evaluates to false. If you
    #     pass a symbol representing an instance method then the result of
    #     the method will be evaluated. Any objects that respond to
    #     <tt>:call</tt> are evaluated as well.  Defaults to false.
    #
    # [:marshal]
    #     If set to true, attributes will be marshaled as well as masker. This
    #     is useful if you're planning on masking something other than a string.
    #     Defaults to false unless you're using it with ActiveRecord or
    #     DataMapper.
    #
    # [:marshaler]
    #     The object to use for marshaling. Defaults to Marshal.
    #
    # [:dump_method]
    #     The dump method name to call on the <tt>:marshaler</tt> object to.
    #     Defaults to 'dump'.
    #
    # [:load_method]
    #     The load method name to call on the <tt>:marshaler</tt> object.
    #     Defaults to 'load'.
    #
    # You can specify your own default options
    #
    #   class User
    #     # now all attributes will be encoded and marshaled by default
    #     attr_masker_options.merge!(:marshal => true, :another_option => true)
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
    #--
    # rubocop:disable Metrics/MethodLength
    def attr_masker(*args)
      default_options = {
        if: true,
        unless: false,
        column_name: nil,
        marshal: false,
        marshaler: Marshal,
        dump_method: "dump",
        load_method: "load",
        masker: AttrMasker::Maskers::Simple.new,
      }

      options = args.extract_options!.
        reverse_merge(attr_masker_options).
        reverse_merge(default_options)

      args.each do |attribute_name|
        attribute = Attribute.new(attribute_name, self, options)
        masker_attributes[attribute.name] = attribute
      end
    end
    # rubocop:enable Metrics/MethodLength

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
  end
end
