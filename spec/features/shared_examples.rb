# (c) 2017 Ribose Inc.
#

# No point in ensuring a trailing comma in multiline argument lists here.
# rubocop:disable Style/TrailingCommaInArguments

require "spec_helper"

RSpec.shared_examples "Attr Masker gem feature specs" do
  before do
    stub_const "User", user_class_definition

    User.class_eval do
      def jedi?
        email.ends_with? "@jedi.example.test"
      end
    end
  end

  let!(:han) do
    User.create!(
      first_name: "Han",
      last_name: "Solo",
      email: "han@example.test",
      avatar: Marshal.dump("Millenium Falcon photo"),
    )
  end

  let!(:luke) do
    User.create!(
      first_name: "Luke",
      last_name: "Skywalker",
      email: "luke@jedi.example.test",
      avatar: Marshal.dump("photo with a light saber"),
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
    reverse_masker = ->(value:, **_) do
      value.reverse
    end

    upcase_masker = ->(value:, **_) do
      value.upcase
    end

    User.class_eval do
      attr_masker :first_name, masker: reverse_masker
      attr_masker :last_name, masker: upcase_masker
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

  example "Masking a marshalled attribute" do
    User.class_eval do
      attr_masker :avatar, marshal: true
    end

    expect { run_rake_task }.not_to(change { User.count })

    expect { han.reload }.to(
      preserve { han.first_name } &
      preserve { han.last_name } &
      preserve { han.email } &
      change { han.avatar }
    )

    expect(han.avatar).to eq(Marshal.dump("(redacted)"))

    expect { luke.reload }.to(
      preserve { luke.first_name } &
      preserve { luke.last_name } &
      preserve { luke.email } &
      change { luke.avatar }
    )

    expect(luke.avatar).to eq(Marshal.dump("(redacted)"))
  end

  example "Masking a marshalled attribute with a custom marshaller" do
    module CustomMarshal
      module_function

      def load_marshalled(*args)
        Marshal.load(*args) # rubocop:disable Security/MarshalLoad
      end

      def dump_json(*args)
        JSON.dump(json: args)
      end
    end

    User.class_eval do
      attr_masker(
        :avatar,
        marshal: true,
        marshaler: CustomMarshal,
        load_method: :load_marshalled,
        dump_method: :dump_json,
      )
    end

    expect { run_rake_task }.not_to(change { User.count })

    expect { han.reload }.to(
      preserve { han.first_name } &
      preserve { han.last_name } &
      preserve { han.email } &
      change { han.avatar }
    )

    expect(han.avatar).to eq({ json: ["(redacted)"] }.to_json)

    expect { luke.reload }.to(
      preserve { luke.first_name } &
      preserve { luke.last_name } &
      preserve { luke.email } &
      change { luke.avatar }
    )

    expect(luke.avatar).to eq({ json: ["(redacted)"] }.to_json)
  end

  example "It is disabled in production environment" do
    allow(Rails).to receive(:env) { "production".inquiry }

    User.class_eval do
      attr_masker :last_name
    end

    expect { run_rake_task }.to(
      preserve { User.count } &
      raise_exception(AttrMasker::Error)
    )

    [han, luke].each do |record|
      expect { record.reload }.not_to(change { record })
    end
  end

  example "It masks records disregarding default scope" do
    User.class_eval do
      attr_masker :last_name

      default_scope ->() { where(last_name: "Solo") }
    end

    expect { run_rake_task }.not_to(change { User.unscoped.count })

    [han, luke].each do |record|
      expect { record.reload }.to(
        change { record.last_name }.to("(redacted)")
      )
    end
  end

  def run_rake_task
    Rake::Task["db:mask"].execute
  end
end
