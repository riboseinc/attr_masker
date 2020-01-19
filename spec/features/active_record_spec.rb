# (c) 2017 Ribose Inc.
#

require_relative "shared_examples"

RSpec.describe "Attr Masker gem", :suppress_progressbar do
  context "when used with ActiveRecord" do
    before do
      if WITHOUT_ACTIVE_RECORD
        expect(defined?(::ActiveRecord)).to be(nil)
        skip "Active Record specs disabled with WITHOUT_ACTIVE_RECORD shell " \
          "variable"
      end
    end

    # For performance reasons, Rails features its own DescendantsTracker,
    # which stores parent-child class relationships, and uses it to find
    # subclasses instead of crawling the ObjectSpace.
    #
    # The drawback is that anonymous classes are never garbage collected,
    # because there is always at least one reference, which is held by that
    # tracker.  Therefore, the return value of ActiveRecord::Base.descendants
    # method call is typically polluted by anonymous classes created by this
    # test suite.  What is worse, that means that tests depend on each other.
    #
    # Till now, we used to stub ActiveRecord::Base.descendants method in specs
    # where it matters, but that did not stop anonymous classes from being
    # carried over to other examples, making the whole test suite quite
    # fragile.  And indeed, issues have been observed with Rails 5.2.
    #
    # This commit introduces a very different approach.  Anonymous classes are
    # removed from DescendantsTracker when respective test example is done.
    # Nothing is carried over, no stubbing is necessary.  It must be noted
    # though that the new approach relies on Rails private APIs.  But
    # fortunately, DescendantsTracker is modified extremely rarely (no changes
    # to AST since 2012), therefore  I expect that this new approach will
    # require much less maintenance than stubbing we did.
    #
    # -----
    # 2020-01
    #
    # From Rails 6.0, DescendantsTracker uses weak references, and no longer
    # blocks garbage collection of anonymous classes.  See:
    # https://github.com/rails/rails/pull/31442
    #
    # However, instances of these classes, which are bound to example life cycle
    # via #let helpers, also hold the references, hence garbage collection must
    # be postponed till example life cycle ends.
    #
    # Consequently, #after hooks cannot be used, as they are run too early for
    # this purpose, but fortunately this can be worked around by
    # before(:example) + after(:all) combo.
    after do
      if ::ActiveSupport.gem_version < Gem::Version.new("6.0.0")
        ::ActiveSupport::DescendantsTracker.
          class_variable_get("@@direct_descendants")[::ActiveRecord::Base].
          delete(user_class_definition)
      end
    end

    before do
      GC.start
    end

    after(:all) do
      GC.start
    end

    # Rails 5.2 seems to reset connection shortly after Combustion gets its job,
    # causing in-memory database to be dropped.  Hence, schema is loaded
    # once again here.
    before(:all) do
      if defined?(::ActiveRecord::Base)
        schema_path = File.expand_path("../dummy/db/schema.rb", __dir__)
        load(schema_path)
      end
    end

    # No point in using ApplicationRecord here.
    # rubocop:disable Rails/ApplicationRecord

    let(:user_class_definition) { Class.new(ActiveRecord::Base) }

    # rubocop:enable Rails/ApplicationRecord

    include_examples "Attr Masker gem feature specs"
  end
end
