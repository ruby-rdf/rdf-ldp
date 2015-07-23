require 'spec_helper'

describe RDF::LDP::RDFSource do
  it_behaves_like 'an RDFSource'

  subject { described_class.new(uri) }

  let(:uri) { RDF::URI('http://ex.org/moomin') }

  describe '#container?' do
    it { is_expected.not_to be_container }
  end
end
