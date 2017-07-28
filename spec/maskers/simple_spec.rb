# (c) 2017 Ribose Inc.
#

# No point in using ApplicationRecord here.

require "spec_helper"

RSpec.describe AttrMasker::Maskers::Simple do
  subject { described_class }

  example { expect(subject.mask(value: "Solo")).to eq("(redacted)") }
  example { expect(subject.mask(value: Math::PI)).to eq("(redacted)") }
  example { expect(subject.mask(value: nil)).to eq("(redacted)") }
end
