require 'spec_helper'

describe RDF::LDP::Resource do
  it_behaves_like 'a Resource' 

  subject { described_class.new(uri) }
  let(:uri) { RDF::URI 'http://example.org/moomin' }

  describe '.find' do
    it 'raises NotFound when the resource does not exist' do
      expect { described_class.find(uri, RDF::Repository.new) }
        .to raise_error RDF::LDP::NotFound
    end
    context 'when the resource exists' do
      before do
        graph << RDF::Statement(uri, RDF::Vocab::DC.title, 'snorkmaiden')
      end

      let(:repository) { RDF::Repository.new }
      let(:graph) do
        RDF::Graph.new(graph_name: uri / '#meta', data: repository)
      end

      it 'gives an RDFSource when no class exists in interaction models' do
        expect(described_class.find(uri, repository))
          .to be_a RDF::LDP::RDFSource
        expect(described_class.find(uri, repository).subject_uri).to eq uri
      end
      
      it 'finds the resource with container interaction model' do
        graph << RDF::Statement(uri, RDF.type, RDF::LDP::Container.to_uri)

        expect(described_class.find(uri, repository))
          .to be_a RDF::LDP::Container
        expect(described_class.find(uri, repository).subject_uri).to eq uri
      end

      it 'finds the resource with non-rdf source interaction model' do
        graph << RDF::Statement(uri, RDF.type, RDF::LDP::NonRDFSource.to_uri)

        expect(described_class.find(uri, repository))
          .to be_a RDF::LDP::NonRDFSource
        expect(described_class.find(uri, repository).subject_uri).to eq uri
      end
    end
  end

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
    
    context 'custom implementation class' do
      let!(:custom_container) { Class.new(RDF::LDP::Container) }

      before do
        @original_class = RDF::LDP::InteractionModel.for(RDF::Vocab::LDP.BasicContainer)
      end
      
      after do
        RDF::LDP::InteractionModel.register(@original_class, for: RDF::Vocab::LDP.BasicContainer)
      end
      
      it 'matches header to class' do
        RDF::LDP::InteractionModel.register(custom_container, for: RDF::Vocab::LDP.BasicContainer)
        header = '<http://www.w3.org/ns/ldp#BasicContainer>;rel="type"'
        expect(described_class.interaction_model(header))
          .to eq custom_container
      end
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
          .to contain_exactly(200, a_hash_including('abc' => 'def'), subject)
      end
    end

    context 'with :HEAD' do
      it 'gives empty response body' do
        expect(subject.request(:HEAD, 200, {'abc' => 'def'}, {}))
          .to contain_exactly(200, a_hash_including('abc' => 'def'), [])
      end
    end

    context 'with :OPTIONS' do
      it 'gives empty response body' do
        expect(subject.request(:OPTIONS, 200, {'abc' => 'def'}, {}))
          .to contain_exactly(200, a_hash_including('abc' => 'def'), [])
      end
    end
  end
end
