require 'spec_helper'

describe RDF::LDP::NonRDFSource do
  it_behaves_like 'a NonRDFSource'

  subject { described_class.new(uri) }
  let(:uri) { RDF::URI 'http://example.org/moomin' }

  describe '.to_uri' do
    it { expect(described_class.to_uri).to be_a RDF::URI }
  end

  describe '#ldp_resource?' do
    it { is_expected.to be_ldp_resource }
  end

  describe '#container?' do
    it { is_expected.not_to be_container }
  end

  describe '#rdf_source?' do
    it { is_expected.not_to be_rdf_source }
  end

  describe '#non_rdf_source?' do
    it { is_expected.to be_non_rdf_source }
  end
end
