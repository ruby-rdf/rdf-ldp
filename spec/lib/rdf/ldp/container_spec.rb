require 'spec_helper'

describe RDF::LDP::Container do
  subject { described_class.new(RDF::URI('http://ex.org/moomin')) }
  it_behaves_like 'a Container'
  
  describe 'CONTAINER_CLASSES' do
    it 'has basic, direct, and indirect' do
      expect(RDF::LDP::CONTAINER_CLASSES.keys)
        .to contain_exactly(:basic, :direct, :indirect)
    end
  end

  describe '#container_class' do
    it 'is a basic container' do
      expect(subject.container_class)
        .to eq RDF::URI('http://www.w3.org/ns/ldp#BasicContainer')
    end
  end

  describe '#make_containment_triple' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'statement subject is #subject_uri' do
      expect(subject.make_containment_triple(resource).subject)
        .to eq subject.subject_uri
    end
  end

  describe '#add_containment_triple' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'adds triple to graph' do
      expect { subject.add_containment_triple(resource) }
        .to change { subject.graph.count }.by(1)
    end
  end
end
