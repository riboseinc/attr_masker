# (c) 2017 Ribose Inc.
#

Combustion.path = "spec/dummy"

unless WITHOUT_ACTIVE_RECORD
  Combustion.initialize! :active_record
else
  Combustion.initialize!
end
