# (c) 2017 Ribose Inc.
#

Combustion.path = "spec/dummy"

if WITHOUT_ACTIVE_RECORD
  Combustion.initialize!
else
  Combustion.initialize! :active_record
end
