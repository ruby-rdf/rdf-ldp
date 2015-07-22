require 'spec_helper'

describe RDF::LDP::RDFSource do
  it_behaves_like 'an RDFSource'

  describe '#container?' do
    it { is_expected.not_to be_container }
  end
end
