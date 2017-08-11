# (c) 2017 Ribose Inc.
#

# No point in using ApplicationRecord here.
# rubocop:disable Rails/ApplicationRecord

require_relative "shared_examples"

RSpec.describe "Attr Masker gem", :suppress_progressbar do
  context "when used with ActiveRecord" do
    before do
      if ENV["WITHOUT_ACTIVE_RECORD"]
        expect(defined?(::ActiveRecord)).to be(nil)
        skip "Active Record specs disabled with WITHOUT_ACTIVE_RECORD shell " \
          "variable"
      end
    end

    before do
      allow(ActiveRecord::Base).to receive(:descendants).
        and_return([ActiveRecord::SchemaMigration, user_class_definition])
    end

    let(:user_class_definition) { Class.new(ActiveRecord::Base) }

    include_examples "Attr Masker gem feature specs"
  end
end
