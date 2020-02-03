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

  describe "#column_names" do
    subject { receiver.method :column_names }
    let(:receiver) { described_class.new :some_attr, :some_model, options }
    let(:options) { {} }

    it "defaults to array containing attribute name only" do
      expect(subject.call).to contain_exactly(:some_attr)
    end

    it "can be overriden with :column_names option" do
      options[:column_names] = :some_column
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

  describe "mask" do
    subject { described_class.instance_method :mask }
    let(:receiver) { described_class.new :some_attr, :some_model, options }
    let(:model_instance) { Struct.new(:some_attr).new("value") }
    let(:options) { { masker: masker } }
    let(:masker) { ->(**) { "masked_value" } }

    it "takes the instance.options[:masker] and calls it" do
      expect(masker).to receive(:call)
      subject.bind(receiver).call(model_instance)
    end

    it "passes the unmarshalled attribute value to the masker" do
      expect(receiver).to receive(:unmarshal_data).
        with("value").and_return("unmarshalled_value")
      expect(masker).to receive(:call).
        with(hash_including(value: "unmarshalled_value"))
      subject.bind(receiver).call(model_instance)
    end

    it "passes the model instance to the masker" do
      expect(masker).to receive(:call).
        with(hash_including(model: model_instance))
      subject.bind(receiver).call(model_instance)
    end

    it "marshals the masked value, and assigns it to the attribute" do
      expect(receiver).to receive(:marshal_data).
        with("masked_value").and_return("marshalled_masked_value")
      subject.bind(receiver).call(model_instance)
      expect(model_instance.some_attr).to eq("marshalled_masked_value")
    end
  end

  describe "#masked_attributes_new_values" do
    subject { receiver.method :masked_attributes_new_values }
    let(:receiver) { described_class.new :some_attr, :some_model, options }
    let(:options) { {} }
    let(:model_instance) { double } # Struct.new(:some_attr, :other_attr) }
    let(:changes) { { some_attr: [nil, "new"], other_attr: [nil, "other"] } }

    before { allow(model_instance).to receive(:changes).and_return(changes) }

    # rubocop:disable Style/BracesAroundHashParameters
    # We are comparing hashes here, and we want hash literals
    it "returns a hash of required database updates which include masked field \
        change, but ignores other attribute changes" do
      expect(subject.(model_instance)).to eq({ some_attr: "new" })
    end

    it "returns an emtpy hash for an unchanged object" do
      changes.clear
      expect(subject.(model_instance)).to eq({})
    end

    it "allows overriding column/field name to be updated with column_name \
      option" do
      options[:column_names] = %i[other_attr]
      expect(subject.(model_instance)).to eq({ other_attr: "other" })
    end

    it "allows specifying more than one column/field name to be updated \
      with column_name option" do
      options[:column_names] = %i[some_attr other_attr]
      expect(subject.(model_instance)).
        to eq({ some_attr: "new", other_attr: "other" })
    end
    # rubocop:enable Style/BracesAroundHashParameters
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
