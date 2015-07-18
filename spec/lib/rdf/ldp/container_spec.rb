require 'spec_helper'

describe RDF::LDP::Container do
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
end
