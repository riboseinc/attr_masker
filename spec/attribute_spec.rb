# (c) 2017 Ribose Inc.
#

require "spec_helper"

RSpec.describe AttrMasker::Attribute do
  describe "::new" do
    subject { described_class.method :new }

    it "instantiates a new attribute definition" do
      opts = { arbitrary: :options }
      retval = subject.call(:some_attr, :some_model, opts)
      expect(retval.name).to eq(:some_attr)
      expect(retval.model).to eq(:some_model)
      expect(retval.options).to eq(opts)
    end
  end
end
