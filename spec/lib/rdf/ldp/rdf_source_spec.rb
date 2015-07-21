require 'spec_helper'

describe RDF::LDP::RDFSource do
  it_behaves_like 'an RDFSource'

  describe '.parse_graph' do
    it 'raises UnsupportedMediaType if no reader found' do
      expect { described_class.parse_graph('graph', 'text/fake') }
        .to raise_error RDF::LDP::UnsupportedMediaType
    end

    it 'raises BadRequest if graph cannot be parsed' do
      expect { described_class.parse_graph('graph', 'text/plain') }
        .to raise_error RDF::LDP::BadRequest
    end

    it 'parses the graph' do
      graph = RDF::Graph.new

      graph << RDF::Statement(RDF::URI('http://ex.org/moomin'), 
                              RDF.type, 
                              RDF::FOAF.Person)

      10.times do
        graph << RDF::Statement(RDF::Node.new,
                                RDF::DC.creator, 
                                RDF::Node.new)
      end

      expect(described_class.parse_graph(graph.dump(:ttl), 'text/turtle'))
        .to be_isomorphic_with graph
    end
  end

  describe '#container?' do
    it { is_expected.not_to be_container }
  end
end
