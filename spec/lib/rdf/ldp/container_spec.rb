require 'spec_helper'

describe RDF::LDP::Container do
  subject { described_class.new(RDF::URI('http://ex.org/moomin')) }
  it_behaves_like 'a Container'
  
  describe 'CONTAINER_CLASSES' do
    it 'has basic, direct, and indirect' do
      expect(described_class::CONTAINER_CLASSES.keys)
        .to contain_exactly(:basic, :direct, :indirect)
    end
  end

  describe '#container_class' do
    it 'is a basic container' do
      expect(subject.container_class)
        .to eq RDF::URI('http://www.w3.org/ns/ldp#BasicContainer')
    end
  end

  describe '#membership_predicate' do
    it 'gives default membership predicate' do
      expect(subject.membership_predicate)
        .to eq RDF::URI('http://www.w3.org/ns/ldp#contains')
    end
  end

  describe '#make_membership_triple' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'statement subject is #subject_uri' do
      expect(subject.make_membership_triple(resource).subject)
        .to eq subject.subject_uri
    end
  end
end
