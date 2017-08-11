# (c) 2017 Ribose Inc.
#

Combustion.path = "spec/dummy"

if ENV["WITHOUT_ACTIVE_RECORD"].nil?
  Combustion.initialize! :active_record
else
  Combustion.initialize!
end
