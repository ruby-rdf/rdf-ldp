require 'spec_helper'

describe RDF::LDP::Resource do
  it_behaves_like 'a Resource' 

  describe '#to_response' do
    it 'raises not implemented' do
      expect { subject.to_response }.to raise_error NotImplementedError
    end
  end

  describe '#container?' do
    it { is_expected.not_to be_container }
  end

  describe '#rdf_source?' do
    it { is_expected.not_to be_rdf_source }
  end

  describe '#non_rdf_source?' do
    it { is_expected.not_to be_non_rdf_source }
  end
end
