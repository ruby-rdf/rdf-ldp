require 'spec_helper'

describe RDF::LDP::Resource do
  describe '.to_uri' do
    it { expect(described_class.to_uri).to be_a RDF::URI }
  end

  describe '#to_response' do
    it 'raises not implemented' do
      expect { subject.to_response }.to raise_error NotImplementedError
    end
  end

  describe '#ldp_resource?' do
    it { is_expected.to be_ldp_resource }
  end

  describe '#rdf_source?' do
    it { is_expected.not_to be_rdf_source }
  end

  describe '#non_rdf_source?' do
    it { is_expected.not_to be_non_rdf_source }
  end
end
