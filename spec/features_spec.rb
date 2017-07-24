# (c) 2017 Ribose Inc.
#

# No point in using ApplicationRecord here.
# rubocop:disable Rails/ApplicationRecord

require "spec_helper"

RSpec.describe "Attr Masker gem" do
  before do
    stub_const "User", Class.new(ActiveRecord::Base)

    User.class_eval do
      def jedi?
        email.ends_with? "@jedi.example.test"
      end
    end

    allow(ActiveRecord::Base).to receive(:descendants).
      and_return([ActiveRecord::SchemaMigration, User])
  end

  let!(:han) do
    User.create!(
      first_name: "Han",
      last_name: "Solo",
      email: "han@example.test",
    )
  end

  let!(:luke) do
    User.create!(
      first_name: "Luke",
      last_name: "Skywalker",
      email: "luke@jedi.example.test",
    )
  end

  example "Masking a single text attribute with default options" do
    User.class_eval do
      attr_masker :last_name
    end

    expect { run_rake_task }.not_to(change { User.count })

    [han, luke].each do |record|
      expect { record.reload }.to(
        change { record.last_name }.to("(redacted)") &
        preserve { record.first_name } &
        preserve { record.email }
      )
    end
  end

  example "Specifying multiple attributes in an attr_masker declaration" do
    User.class_eval do
      attr_masker :first_name, :last_name
    end

    expect { run_rake_task }.not_to(change { User.count })

    [han, luke].each do |record|
      expect { record.reload }.to(
        change { record.first_name }.to("(redacted)") &
        change { record.last_name }.to("(redacted)") &
        preserve { record.email }
      )
    end
  end

  example "Skipping some records when a symbol is passed to :if option" do
    User.class_eval do
      attr_masker :first_name, :last_name, if: :jedi?
    end

    expect { run_rake_task }.not_to(change { User.count })

    expect { han.reload }.to(
      preserve { han.first_name } &
      preserve { han.last_name } &
      preserve { han.email }
    )

    expect { luke.reload }.to(
      change { luke.first_name }.to("(redacted)") &
      change { luke.last_name }.to("(redacted)") &
      preserve { luke.email }
    )
  end

  example "Skipping some records when a lambda is passed to :if option" do
    User.class_eval do
      attr_masker :first_name, :last_name, if: ->(r) { r.jedi? }
    end

    expect { run_rake_task }.not_to(change { User.count })

    expect { han.reload }.to(
      preserve { han.first_name } &
      preserve { han.last_name } &
      preserve { han.email }
    )

    expect { luke.reload }.to(
      change { luke.first_name }.to("(redacted)") &
      change { luke.last_name }.to("(redacted)") &
      preserve { luke.email }
    )
  end

  example "Skipping some records when a symbol is passed to :unless option" do
    User.class_eval do
      attr_masker :first_name, :last_name, unless: :jedi?
    end

    expect { run_rake_task }.not_to(change { User.count })

    expect { han.reload }.to(
      change { han.first_name }.to("(redacted)") &
      change { han.last_name }.to("(redacted)") &
      preserve { han.email }
    )

    expect { luke.reload }.to(
      preserve { luke.first_name } &
      preserve { luke.last_name } &
      preserve { luke.email }
    )
  end

  example "Skipping some records when a lambda is passed to :unless option" do
    User.class_eval do
      attr_masker :first_name, :last_name, unless: ->(r) { r.jedi? }
    end

    expect { run_rake_task }.not_to(change { User.count })

    expect { han.reload }.to(
      change { han.first_name }.to("(redacted)") &
      change { han.last_name }.to("(redacted)") &
      preserve { han.email }
    )

    expect { luke.reload }.to(
      preserve { luke.first_name } &
      preserve { luke.last_name } &
      preserve { luke.email }
    )
  end

  example "Using a custom masker" do
    custom_masker = Object.new

    def custom_masker.mask(value:, **_)
      value.reverse
    end

    def custom_masker.upcase(value:, **_)
      value.upcase
    end

    User.class_eval do
      attr_masker :first_name, masker: custom_masker
      attr_masker :last_name, masker: custom_masker, mask_method: :upcase
    end

    expect { run_rake_task }.not_to(change { User.count })

    expect { han.reload }.to(
      change { han.first_name }.to("naH") &
      change { han.last_name }.to("SOLO") &
      preserve { han.email }
    )

    expect { luke.reload }.to(
      change { luke.first_name }.to("ekuL") &
      change { luke.last_name }.to("SKYWALKER") &
      preserve { luke.email }
    )
  end

  def run_rake_task
    Rake::Task["db:mask"].execute
  end
end
