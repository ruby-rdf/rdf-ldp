require 'spec_helper'

describe RDF::LDP::NonRDFSource do
  describe '.to_uri' do
    it { expect(described_class.to_uri).to be_a RDF::URI }
  end

  describe '#ldp_resource?' do
    it { is_expected.to be_ldp_resource }
  end

  describe '#rdf_source?' do
    it { is_expected.not_to be_rdf_source }
  end

  describe '#non_rdf_source?' do
    it { is_expected.to be_non_rdf_source }
  end
end
