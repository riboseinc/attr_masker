# (c) 2017 Ribose Inc.
#

require_relative "shared_examples"

RSpec.describe "Attr Masker gem", :suppress_progressbar do
  context "when used with Mongoid" do
    before do
      if WITHOUT_MONGOID
        expect(defined?(::Mongoid)).to be(nil)
        skip "Mongoid specs disabled with WITHOUT=mongoid shell variable"
      end
    end

    after do
      # Remove the example-specific model from Mongoid.models
      ::Mongoid.models.delete(user_class_definition) if defined?(::Mongoid)
    end

    let(:user_class_definition) do
      Class.new do
        include Mongoid::Document
        include Mongoid::Timestamps

        store_in collection: "users"

        field :first_name
        field :last_name
        field :email
        field :avatar
      end
    end

    include_examples "Attr Masker gem feature specs"
  end
end
