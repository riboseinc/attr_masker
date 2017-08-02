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

  describe "#column_name" do
    subject { receiver.method :column_name }
    let(:receiver) { described_class.new :some_attr, :some_model, options }
    let(:options) { {} }

    it "defaults to attribute name" do
      expect(subject.call).to eq(:some_attr)
    end

    it "can be overriden with :column_name option" do
      options[:column_name] = :some_column
      expect(subject.call).to eq(:some_column)
    end
  end
end
