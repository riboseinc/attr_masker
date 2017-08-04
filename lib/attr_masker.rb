# (c) 2017 Ribose Inc.
#

# Adds attr_accessors that mask an object's attributes
module AttrMasker
  autoload :Version, "attr_masker/version"
  autoload :Attribute, "attr_masker/attribute"
  autoload :Model, "attr_masker/model"

  autoload :Error, "attr_masker/error"
  autoload :Performer, "attr_masker/performer"

  module Maskers
    autoload :Replacing, "attr_masker/maskers/replacing"
    autoload :SIMPLE, "attr_masker/maskers/simple"
  end

  require "attr_masker/railtie" if defined?(Rails)
end

Object.extend AttrMasker::Model
