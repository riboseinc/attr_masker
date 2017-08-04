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

  describe "#should_mask?" do
    subject { described_class.instance_method :should_mask? }

    let(:model_instance) { double }
    let(:truthy) { double call: true }
    let(:falsey) { double call: false }

    example { expect(retval_for_opts({})).to be(true) }
    example { expect(retval_for_opts(if: truthy)).to be(true) }
    example { expect(retval_for_opts(if: falsey)).to be(false) }
    example { expect(retval_for_opts(unless: truthy)).to be(false) }
    example { expect(retval_for_opts(unless: falsey)).to be(true) }
    example { expect(retval_for_opts(if: truthy, unless: truthy)).to be(false) }
    example { expect(retval_for_opts(if: truthy, unless: falsey)).to be(true) }
    example { expect(retval_for_opts(if: falsey, unless: truthy)).to be(false) }
    example { expect(retval_for_opts(if: falsey, unless: falsey)).to be(false) }

    def retval_for_opts(opts)
      receiver = described_class.new(:some_attr, :some_model, opts)
      callable = subject.bind(receiver)
      callable.(model_instance)
    end
  end

  describe "#evaluate_option" do
    subject { receiver.method :evaluate_option }
    let(:receiver) { described_class.new :some_attr, model_instance, options }
    let(:options) { {} }
    let(:model_instance) { double }
    let(:retval) { subject.call(:option_name, model_instance) }

    context "when that option value is a symbol" do
      let(:options) { { option_name: :meth } }

      before do
        allow(model_instance).to receive(:meth).with(no_args).and_return(:rv)
      end

      it "evaluates an object's method pointed by that symbol" do
        expect(retval).to be(:rv)
      end
    end

    context "when that option_nameion value responds to #call" do
      let(:options) { { option_name: callable } }
      let(:callable) { double }

      before do
        allow(callable).to receive(:call).with(model_instance).and_return(:rv)
      end

      it "calls #call on it passing model instance as the only argument" do
        expect(retval).to be(:rv)
      end
    end
  end

  describe "#marshal_data" do
    subject { receiver.method :marshal_data }
    let(:receiver) { described_class.new :some_attr, model_instance, options }
    let(:options) { { marshaler: marshaller, dump_method: :dump_m } }
    let(:marshaller) { double }
    let(:model_instance) { double }

    it "returns unmodified argument when marshal option is falsey" do
      options[:marshal] = false
      expect(subject.call(:data)).to be(:data)
    end

    it "returns unmodified argument when marshal option is falsey" do
      options[:marshal] = true
      expect(marshaller).to receive(:dump_m).with(:data).and_return(:retval)
      expect(subject.call(:data)).to be(:retval)
    end
  end

  describe "#unmarshal_data" do
    subject { receiver.method :unmarshal_data }
    let(:receiver) { described_class.new :some_attr, model_instance, options }
    let(:options) { { marshaler: marshaller, load_method: :load_m } }
    let(:marshaller) { double }
    let(:model_instance) { double }

    it "returns unmodified argument when marshal option is falsey" do
      options[:marshal] = false
      expect(subject.call(:data)).to be(:data)
    end

    it "returns unmodified argument when marshal option is falsey" do
      options[:marshal] = true
      expect(marshaller).to receive(:load_m).with(:data).and_return(:retval)
      expect(subject.call(:data)).to be(:retval)
    end
  end
end
