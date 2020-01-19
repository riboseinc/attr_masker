# Copied from Mongoid's test suite
# https://github.com/mongodb/mongoid/blob/v6.2.0/spec/spec_helper.rb

# These environment variables can be set if wanting to test against a database
# that is not on the local machine.
ENV["MONGOID_SPEC_HOST"] ||= "127.0.0.1"
ENV["MONGOID_SPEC_PORT"] ||= "27017"

require "mongoid" unless WITHOUT_MONGOID
