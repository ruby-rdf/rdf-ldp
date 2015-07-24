
shared_examples 'a Resource' do
  describe '.to_uri' do
    it { expect(described_class.to_uri).to be_a RDF::URI }
  end

  subject { described_class.new(uri) }
  let(:uri) { RDF::URI 'http://example.org/moomin' }

  it { is_expected.to be_ldp_resource }
  it { is_expected.to respond_to :container? }
  it { is_expected.to respond_to :rdf_source? }
  it { is_expected.to respond_to :non_rdf_source? }

  describe '#allowed_methods' do
    it 'responds to all methods returned' do
      subject.allowed_methods.each do |method|
        expect(subject.respond_to?(method.downcase, true)).to be true
      end
    end

    it 'includes the MUST methods' do
      expect(subject.allowed_methods).to include(*[:GET, :OPTIONS, :HEAD])
    end
  end

  describe '#create' do
    it 'accepts two args' do
      expect(described_class.instance_method(:create).arity).to eq 2
    end

    it 'adds a type triple to metagraph' do
      subject.create('', 'text/plain')
      expect(subject.metagraph)
        .to have_statement RDF::Statement(subject.subject_uri, 
                                          RDF.type, 
                                          described_class.to_uri)
    end

    it 'marks resource as existing' do
      expect { subject.create('', 'text/plain') }
        .to change { subject.exists? }.from(false).to(true)
    end
  end

  describe '#update' do
    it 'accepts two args' do
      expect(described_class.instance_method(:update).arity).to eq 2
    end
  end

  describe '#destroy' do
    it 'accepts no args' do
      expect(described_class.instance_method(:destroy).arity).to eq 0
    end
  end

  describe '#metagraph' do
    it 'returns a graph' do
      expect(subject.metagraph).to be_a RDF::Graph
    end

    it 'has the metagraph name for the resource' do
      expect(subject.metagraph.context).to eq subject.subject_uri / '#meta'
    end
  end

  describe '#to_response' do
    it 'returns an object that responds to #each' do
      expect(subject.to_response).to respond_to :each
    end
  end

  describe '#request' do
    it 'sends the message to itself' do
      expect(subject).to receive(:blah)
      subject.request(:BLAH, 200, {}, {})
    end

    it 'raises MethodNotAllowed when method is unimplemented' do
      allow(subject).to receive(:not_implemented)
                         .and_raise NotImplementedError
      expect { subject.request(:not_implemented, 200, {}, {}) }
        .to raise_error(RDF::LDP::MethodNotAllowed)
    end

    it 'responds to :GET' do
      expect { subject.request(:GET, 200, {}, {}) }.not_to raise_error
    end

    it 'responds to :HEAD' do
      expect { subject.request(:OPTIONS, 200, {}, {}) }.not_to raise_error
    end

    it 'responds to :OPTIONS' do
      expect { subject.request(:OPTIONS, 200, {}, {}) }.not_to raise_error
    end
  end
end

shared_examples 'an RDFSource' do
  it_behaves_like 'a Resource'
  
  let(:uri) { RDF::URI('http://ex.org/moomin') }
  subject { described_class.new('http://ex.org/moomin') }
  it { is_expected.to be_rdf_source }
  it { is_expected.not_to be_non_rdf_source }

  describe '#parse_graph' do
    it 'raises UnsupportedMediaType if no reader found' do
      expect { subject.send(:parse_graph, 'graph', 'text/fake') }
        .to raise_error RDF::LDP::UnsupportedMediaType
    end

    it 'raises BadRequest if graph cannot be parsed' do
      expect { subject.send(:parse_graph, 'graph', 'text/plain') }
        .to raise_error RDF::LDP::BadRequest
    end

    describe 'parsing the graph' do
      let(:graph) { RDF::Graph.new }

      before do
        graph << RDF::Statement(RDF::URI('http://ex.org/moomin'), 
                                RDF.type, 
                                RDF::FOAF.Person)

        10.times do
          graph << RDF::Statement(RDF::Node.new,
                                  RDF::DC.creator, 
                                  RDF::Node.new)
        end
      end

      it 'parses turtle' do
        expect(subject.send(:parse_graph, graph.dump(:ttl), 'text/turtle'))
          .to be_isomorphic_with graph
      end

      it 'parses ntriples' do
        expect(subject.send(:parse_graph, graph.dump(:ntriples), 'text/plain'))
          .to be_isomorphic_with graph
      end
    end
  end

  describe '#etag' do
    before do
      subject.graph << statement
      other.graph << statement
    end

    let(:other) { described_class.new(RDF::URI('http://ex.org/blah')) }

    let(:statement) do
      RDF::Statement(RDF::URI('http://ex.org/m'), RDF::DC.title, 'moomin')
    end

    it 'is the same for equal graphs' do
      expect(subject.etag).to eq other.etag
    end

    it 'is different for differnt graphs' do
      subject.graph << RDF::Statement(RDF::Node.new, RDF::DC.title, 'mymble')
      expect(subject.etag).not_to eq other.etag
    end
  end

  describe '#create' do
    let(:subject) { described_class.new(RDF::URI('http://ex.org/m')) }
    let(:graph) { RDF::Graph.new }
    
    it 'returns itself' do
      expect(subject.create(graph.dump(:ttl), 'text/turtle')).to eq subject
    end

    it 'interprets NULL URI as this resource' do
      graph << RDF::Statement(RDF::URI(), RDF::DC.title, 'moomin')

      expect(subject.create(graph.dump(:ttl), 'text/turtle').graph)
        .to have_statement RDF::Statement(subject.subject_uri, 
                                          RDF::DC.title, 
                                          'moomin')
    end

    it 'interprets Relatives URI as this based on this resource' do
      graph << RDF::Statement(subject.subject_uri, 
                              RDF::DC.isPartOf, 
                              RDF::URI('#moomin'))
      
      expect(subject.create(graph.dump(:ttl), 'text/turtle').graph)
        .to have_statement RDF::Statement(subject.subject_uri,
                                          RDF::DC.isPartOf, 
                                          subject.subject_uri / '#moomin')
    end
  end

  describe '#update' do
    it 'is implemented'
  end

  describe '#destory' do
    it 'is implemented'
  end

  describe '#graph' do
    it 'has a graph' do
      expect(subject.graph).to be_a RDF::Enumerable
    end
  end

  describe '#subject_uri' do
    let(:uri) { RDF::URI('http://ex.org/moomin') }

    it 'has a uri getter' do
      expect(subject.subject_uri).to eq uri
    end

    it 'aliases to #to_uri' do
      expect(subject.to_uri).to eq uri
    end
  end

  describe '#to_response' do
    it 'gives the graph minus context' do
      expect(subject.to_response.context).to eq nil
    end
  end

  describe '#request' do
    context 'with :GET' do
      it 'gives the subject' do
        expect(subject.request(:GET, 200, {'abc' => 'def'}, {}))
          .to contain_exactly(200, a_hash_including('abc' => 'def'), subject)
      end
    end
    
    context 'with :PUT' do
      let(:graph) { RDF::Graph.new }
      let(:env) do
        { 'rack.input' => graph.dump(:ntriples),
          'CONTENT_TYPE' => 'text/plain' }
      end

      context 'when subject exists' do
        before do
          subject.metagraph << RDF::Statement(subject.subject_uri,
                                              RDF.type,
                                              RDF::LDP::RDFSource)
        end
        
        it 'replaces the graph with the input' do
          expect(subject.request(:PUT, 200, {'abc' => 'def'}, env))
            .to contain_exactly(200, a_hash_including('abc' => 'def'), subject)
        end
      end
    end
  end
end

shared_examples 'a Container' do
  it_behaves_like 'an RDFSource'

  let(:uri) { RDF::URI('http://ex.org/moomin') }
  subject { described_class.new(uri) }

  it { is_expected.to be_container }

  describe '#container_class' do
    it 'returns a uri' do
      expect(subject.container_class).to be_a RDF::URI
    end
  end

  describe '#membership_constant_uri' do
    it 'aliases #subject_uri' do
      expect(subject.membership_constant_uri).to eq subject.subject_uri
    end
  end

  describe '#membership_predicate' do
    it 'returns a uri' do
      expect(subject.membership_predicate).to be_a RDF::URI
    end
  end

  describe '#membership_triples' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'returns a uri' do
      subject.add_membership_triple(resource)
      expect(subject.membership_triples)
        .to contain_exactly(an_instance_of(RDF::Statement))
    end
  end

  describe '#add_membership_triple' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'returns self' do
      expect(subject.add_membership_triple(resource)).to eq subject
    end

    it 'membership triple is added to graph' do
      expect(subject.add_membership_triple(resource).graph)
        .to include subject.make_membership_triple(resource)
    end
  end

  describe '#make_membership_triple' do
    let(:resource) { uri / 'papa' }

    it 'returns a statement' do
      expect(subject.make_membership_triple(resource)).to be_a RDF::Statement
    end

    it 'statement subject *or* object is #subject_uri' do
      sub = subject.make_membership_triple(resource).subject
      obj = subject.make_membership_triple(resource).object
      expect([sub, obj]).to include subject.subject_uri
    end

    it 'converts Resource classes to URI' do
      sub = subject.make_membership_triple(subject).subject
      obj = subject.make_membership_triple(subject).object
      expect([sub, obj]).to include subject.subject_uri
    end
  end

  describe '#request' do
    context 'when POST is implemented', 
            if: described_class.private_method_defined?(:post) do
      let(:graph) { RDF::Graph.new }

      let(:env) do
        { 'rack.input' => graph.dump(:ntriples),
          'CONTENT_TYPE' => 'text/plain' }
      end

      it 'returns status 201' do
        expect(subject.request(:POST, 200, {}, env).first).to eq 201
      end

      it 'gives created resource as body' do
        expect(subject.request(:POST, 200, {}, env).last)
          .to be_a RDF::LDP::Resource
      end

      it 'generates an id' do
        expect(subject.request(:POST, 200, {}, env).last.subject_uri)
          .to be_starts_with subject.subject_uri.to_s
      end

      it 'adds membership statement to resource' do
        expect { subject.request(:POST, 200, {}, env) }
          .to change { subject.membership_triples.count }.by(1)
      end

      context 'with Container interaction model' do
        it 'creates a basic container' do
          env['Link'] = "<#{RDF::LDP::Container.to_uri}>;rel=\"type\""
          expect(subject.request(:POST, 200, {}, env).last)
            .to be_a RDF::LDP::Container
        end

        context 'BasicContainer' do
          it 'creates a basic container' do
            env['Link'] = 
              "<http://www.w3.org/ns/ldp#BasicContainer>;rel=\"type\""
            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::Container
          end
        end

        context 'DirectContainer' do
          it 'creates a direct container' do
            env['Link'] = "<#{RDF::LDP::DirectContainer.to_uri}>;rel=\"type\""
            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::DirectContainer
          end
        end

        context 'IndirectContainer' do
          it 'creates a indirect container' do
            env['Link'] = "<#{RDF::LDP::IndirectContainer.to_uri}>;rel=\"type\""
            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::IndirectContainer
          end
        end
      end

      context 'with a Slug' do
        it 'creates resource with Slug' do
          env['Slug'] = 'snork'
          expect(subject.request(:POST, 200, {}, env).last.subject_uri)
            .to eq (subject.subject_uri / env['Slug'])
        end

        it 'mints a uri when empty Slug is given' do
          env['Slug'] = ''
          expect(subject.request(:POST, 200, {}, env).last.subject_uri)
            .to be_starts_with (subject.subject_uri)
        end

        it 'raises a 409 Conflict when slug is already taken' do
          env['Slug'] = 'snork'
          subject.request(:POST, 200, {}, env)

          expect { subject.request(:POST, 200, {}, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'raises a 406 NotAcceptable if slug has a uri fragment `#`' do
          env['Slug'] = 'snork#maiden'

          expect { subject.request(:POST, 200, {}, env) }
            .to raise_error RDF::LDP::NotAcceptable
        end

        it 'url-encodes Slug' do
          env['Slug'] = 'snork maiden'
          expect(subject.request(:POST, 200, {}, env).last.subject_uri)
            .to eq (subject.subject_uri / 'snork%20maiden')
        end
      end
      
      context 'with graph content' do
        before do
          graph << RDF::Statement(uri, RDF::DC.title, 'moomin')
          graph << RDF::Statement(RDF::Node.new, RDF.type, RDF::FOAF.Person)
          graph << RDF::Statement(RDF::Node.new, RDF::DC.creator, 'tove')
        end

        it 'parses graph into created resource' do
          expect(subject.request(:POST, 200, {}, env).last.to_response)
            .to be_isomorphic_with graph
        end

        it 'adds a Location header' do
          expect(subject.request(:POST, 200, {}, env)[1]['Location'])
            .to start_with subject.subject_uri.to_s
        end

        context 'with quads' do
          let(:graph) do
            RDF::Graph.new(subject.subject_uri, data: RDF::Repository.new)
          end

          let(:env) do
            { 'rack.input' => graph.dump(:nquads),
              'CONTENT_TYPE' => 'application/n-quads' }
          end

          it 'parses graph into created resource without regard for context' do
            context_free_graph = RDF::Graph.new
            context_free_graph << graph.statements

            expect(subject.request(:POST, 200, {}, env).last.to_response)
              .to be_isomorphic_with context_free_graph
          end
        end
      end
    end
  end
end
