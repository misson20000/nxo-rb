RSpec.describe Nxo::NsoFile do
  it "parses a valid compressed NSO file" do
    Nxo::NsoFile.new(File.open("spec/test_valid.nso", "rb"))
  end

  it "parses a valid uncompressed NSO file" do
    Nxo::NsoFile.new(File.open("spec/test_valid_uncompressed.nso", "rb"))
  end

  it "fails on hash mismatch" do
    expect do
      Nxo::NsoFile.new(File.open("spec/test_bad_hash.nso", "rb"))
    end.to raise_error(Nxo::Error::HashCheckError)
  end
end
