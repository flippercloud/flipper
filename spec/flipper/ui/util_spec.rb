require 'flipper/ui/util'

RSpec.describe Flipper::UI::Util do
  describe '#blank?' do
    context 'with a string' do
      it 'returns true if blank' do
        expect(described_class.blank?(nil)).to be(true)
        expect(described_class.blank?('')).to be(true)
        expect(described_class.blank?('   ')).to be(true)
      end

      it 'returns false if not blank' do
        expect(described_class.blank?('nope')).to be(false)
      end
    end
  end

  describe '#normalize_feature_name' do
    it 'transliterates accented characters to ascii' do
      expect(described_class.normalize_feature_name('café')).to eq('cafe')
    end

    it 'removes invisible characters' do
      expect(described_class.normalize_feature_name("f\u200Beá\u2060ture")).to eq('feature')
    end

    it 'strips surrounding whitespace' do
      expect(described_class.normalize_feature_name('  notifications_next  ')).to eq('notifications_next')
    end

    it 'returns empty string for nil' do
      expect(described_class.normalize_feature_name(nil)).to eq('')
    end
  end
end
