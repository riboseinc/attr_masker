# (c) 2017 Ribose Inc.
#

require "spec_helper"

RSpec.describe AttrMasker::Model do
  it "extends every class and provides class methods" do
    c = Class.new
    expect(c).to respond_to(:attr_masker)
    expect(c.singleton_class.included_modules).to include(described_class)
  end
end
