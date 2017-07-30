# (c) 2017 Ribose Inc.
#

# No point in using ApplicationRecord here.

require "spec_helper"

RSpec.describe AttrMasker::Maskers::SIMPLE do
  subject { described_class }

  example { expect(subject.(value: "Solo")).to eq("(redacted)") }
  example { expect(subject.(value: Math::PI)).to eq("(redacted)") }
  example { expect(subject.(value: nil)).to eq("(redacted)") }
end
