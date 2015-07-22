require 'spec_helper'

describe RDF::LDP::Resource do
  it_behaves_like 'a Resource' 

  describe '.interaction_model' do
    it 'matches header to class' do
      header = '<http://www.w3.org/ns/ldp#BasicContainer>;rel="type"'
      expect(described_class.interaction_model(header))
        .to eq RDF::LDP::Container
    end

    it 'matches Resource to RDFSource' do
      header = '<http://www.w3.org/ns/ldp#Resource>;rel="type"'
      expect(described_class.interaction_model(header))
        .to eq RDF::LDP::RDFSource
    end

    it 'matches to narrower class' do
      header = '<http://www.w3.org/ns/ldp#RDFSource>;rel="type",' \
               '<http://www.w3.org/ns/ldp#BasicContainer>;rel="type"'
      expect(described_class.interaction_model(header))
        .to eq RDF::LDP::Container
    end

    it 'matches to narrower class NonRDFSource' do
      header = '<http://www.w3.org/ns/ldp#Resource>;rel="type",' \
               '<http://www.w3.org/ns/ldp#NonRDFSource>;rel="type"'
      expect(described_class.interaction_model(header))
        .to eq RDF::LDP::NonRDFSource
    end

    it 'rejects conflicting source types ' do
      header = '<http://www.w3.org/ns/ldp#RDFSource>;rel="type",' \
               '<http://www.w3.org/ns/ldp#NonRDFSource>;rel="type"'
      expect { described_class.interaction_model(header) }
        .to raise_error RDF::LDP::NotAcceptable
    end

    it 'rejects conflicting container types' do
      header = '<http://www.w3.org/ns/ldp#NonRDFSource>;rel="type",' \
               '<http://www.w3.org/ns/ldp#IndirectContainer>;rel="type"'
      expect { described_class.interaction_model(header) }
        .to raise_error RDF::LDP::NotAcceptable
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

  describe '#request' do
    context 'with :GET' do
      it 'echos the request' do
        expect(subject.request(:GET, 200, {'abc' => 'def'}, {}))
          .to eq [200, {'abc' => 'def'}, subject]
      end
    end

    context 'with :HEAD' do
      it 'gives empty response body' do
        expect(subject.request(:HEAD, 200, {'abc' => 'def'}, {}))
          .to eq [200, {'abc' => 'def'}, []]
      end
    end

    context 'with :OPTIONS' do
      it 'gives empty response body' do
        expect(subject.request(:OPTIONS, 200, {'abc' => 'def'}, {}))
          .to eq [200, {'abc' => 'def'}, []]
      end
    end
  end
end
