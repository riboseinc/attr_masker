# (c) 2017 Ribose Inc.
#

# No point in using ApplicationRecord here.

require "spec_helper"

RSpec.describe AttrMasker::Maskers::Replacing do
  subject { described_class.new **options }

  let(:address) { "1 Pedder Street, Hong Kong" }

  shared_examples "AttrMasker::Maskers::Replacing examples" do
    example { expect(subject.(value: address)).to eq(expected_masked_address) }
    example { expect(subject.(value: Math::PI)).to eq(Math::PI) }
    example { expect(subject.(value: nil)).to eq(nil) }
  end

  context "with default options" do
    let(:options) { {} }
    let(:expected_masked_address) { "**************************" }
    include_examples "AttrMasker::Maskers::Replacing examples"
  end

  context "with alphanum_only option set to true" do
    let(:options) { { alphanum_only: true } }
    let(:expected_masked_address) { "* ****** ******, **** ****" }
    include_examples "AttrMasker::Maskers::Replacing examples"
  end

  context "with a custom replacement string" do
    let(:options) { { replacement: "X" } }
    let(:expected_masked_address) { "XXXXXXXXXXXXXXXXXXXXXXXXXX" }
    include_examples "AttrMasker::Maskers::Replacing examples"
  end

  context "with an empty replacement string" do
    let(:options) { { replacement: "" } }
    let(:expected_masked_address) { "" }
    include_examples "AttrMasker::Maskers::Replacing examples"
  end

  context "with alphanum_only and replacement options combined" do
    let(:options) { { alphanum_only: true, replacement: "X" } }
    let(:expected_masked_address) { "X XXXXXX XXXXXX, XXXX XXXX" }
    include_examples "AttrMasker::Maskers::Replacing examples"
  end
end
