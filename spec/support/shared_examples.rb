
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
      subject.create(StringIO.new(''), 'text/plain')
      expect(subject.metagraph)
        .to have_statement RDF::Statement(subject.subject_uri, 
                                          RDF.type, 
                                          described_class.to_uri)
    end

    it 'marks resource as existing' do
      expect { subject.create(StringIO.new(''), 'text/plain') }
        .to change { subject.exists? }.from(false).to(true)
    end

    it 'raises Conlict when already exists' do
      subject.create(StringIO.new(''), 'text/plain')
      expect { subject.create(StringIO.new(''), 'text/plain') }
        .to raise_error RDF::LDP::Conflict
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

shared_examples 'a NonRDFSource' do
  it_behaves_like 'a Resource'

  subject { described_class.new(uri) }
  let(:uri) { RDF::URI 'http://example.org/moomin' }

  let(:contents) { StringIO.new('mummi') }
  
  after { subject.destroy }

  describe '#non_rdf_source?' do
    it { is_expected.to be_non_rdf_source }
  end

  describe '#create' do
    it 'writes the input to body' do
      subject.create(contents, 'text/plain')
      contents.rewind
      expect(subject.to_response.each.to_a).to eq contents.each.to_a
    end

    it 'sets #content_type' do
      expect { subject.create(StringIO.new(''), 'text/plain') }
        .to change { subject.content_type }.to('text/plain')
    end

    it 'persists to resource' do
      repo = RDF::Repository.new
      saved = described_class.new(uri, repo)

      saved.create(contents, 'text/plain')
      contents.rewind

      loaded = RDF::LDP::Resource.find(uri, repo)
      expect(loaded.to_response.each.to_a).to eq contents.each.to_a
    end

    it 'creates an LDP::RDFSource' do
      repo = RDF::Repository.new
      saved = described_class.new(uri, repo)
      description = RDF::LDP::RDFSource.new(subject.description_uri, repo)

      expect { saved.create(contents, 'text/plain') }
        .to change { description.exists? }.from(false).to(true)
    end
  end

  describe '#update' do
    before { subject.create(contents, 'text/plain') }

    it 'writes the input to body' do
      new_contents = StringIO.new('snorkmaiden')
      expect { subject.update(new_contents, 'text/plain') }
        .to change { subject.to_response.to_a }
             .from(a_collection_containing_exactly('mummi'))
             .to(a_collection_containing_exactly('snorkmaiden'))
    end

    it 'updates #content_type' do
      expect { subject.update(contents, 'text/prs.moomin') }
        .to change { subject.content_type }
             .from('text/plain').to('text/prs.moomin')
    end
  end

  describe '#description' do
    it 'is not found' do
      expect { subject.description }.to raise_error RDF::LDP::NotFound
    end

    context 'when it exists' do
      before { subject.create(StringIO.new(''), 'text/plain') }

      it 'is an RDFSource' do
        expect(subject.description).to be_rdf_source
      end

      it 'is the description uri' do
        expect(subject.description.to_uri).to eq subject.description_uri
      end
    end
  end

  describe '#description_uri' do
    it 'is a uri' do
      expect(subject.description_uri).to be_a RDF::URI
    end
  end

  describe '#to_response' do
    it 'gives an empty response if it is new' do
      expect(subject.to_response.to_a).to eq []
    end

    it 'does not create a non-existant file' do
      subject.to_response
      expect(subject.storage.send(:file_exists?)).to be false
    end
  end

  describe '#destroy' do
    before { subject.create(contents, 'text/plain') }

    it 'deletes the content' do
      expect { subject.destroy }
        .to change { subject.to_response.to_a }
             .from(a_collection_containing_exactly('mummi')).to([])
    end

    it 'marks resource as destroyed' do
      expect { subject.destroy }
        .to change { subject.destroyed? }.from(false).to(true)
    end
  end

  describe '#content_type' do
    it 'sets and gets a content_type' do
      expect { subject.content_type = 'text/plain' }
        .to change { subject.content_type }.to('text/plain')
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
    let(:statement) do
      RDF::Statement(subject.subject_uri, RDF::DC.title, 'moomin')
    end

    let(:graph) { RDF::Graph.new << statement }
    let(:content_type) { 'text/turtle' }
    
    shared_examples 'updating rdf_sources' do
      it 'changes the response' do
        expect { subject.update(graph.dump(:ttl), content_type) }
          .to change { subject.to_response }
      end

      it 'changes etag' do
        expect { subject.update(graph.dump(:ttl), content_type) }
          .to change { subject.etag }
      end

      it 'raises UnsupportedMediaType' do
        expect { subject.update(graph.dump(:ttl), 'text/moomin') }
          .to raise_error RDF::LDP::UnsupportedMediaType
      end
    end

    include_examples 'updating rdf_sources' 

    context 'when it exists' do
      before { subject.create('', 'text/plain') }

      include_examples 'updating rdf_sources' 
    end
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

      it 'returns 410 GONE when destroyed' do
        allow(subject).to receive(:destroyed?).and_return true
        expect { subject.request(:GET, 200, {'abc' => 'def'}, {}) }
          .to raise_error RDF::LDP::Gone
      end
    end

    context 'with :DELETE' do
      before { subject.create('', 'text/plain') }

      it 'returns 204' do
        expect(subject.request(:DELETE, 200, {}, {}).first).to eq 204
      end

      it 'returns an empty body' do
        expect(subject.request(:DELETE, 200, {}, {}).last.to_response)
          .to be_empty
      end

      it 'marks resource as destroyed' do
        expect { subject.request(:DELETE, 200, {}, {}) }
          .to change { subject.destroyed? }.from(false).to(true)
      end
    end
    
    context 'with :PUT',
            if: described_class.private_method_defined?(:put) do
      let(:graph) { RDF::Graph.new }
      let(:env) do
        { 'rack.input' => graph.dump(:ntriples),
          'CONTENT_TYPE' => 'text/plain' }
      end

      it 'creates the resource' do
        expect { subject.request(:PUT, 200, {'abc' => 'def'}, env) }
          .to change { subject.exists? }.from(false).to(true)
      end

      it 'responds 201' do
        expect(subject.request(:PUT, 200, {'abc' => 'def'}, env).first)
          .to eq 201
      end

      it 'returns the etag' do
        expect(subject.request(:PUT, 200, {'abc' => 'def'}, env)[1]['ETag'])
          .to eq subject.etag
      end

      context 'when subject exists' do
        before { subject.create('', 'text/plain') }
        
        it 'responds 200' do
          expect(subject.request(:PUT, 200, {'abc' => 'def'}, env))
            .to contain_exactly(200, a_hash_including('abc' => 'def'), subject)
        end

        it 'replaces the graph with the input' do
          graph << RDF::Statement(subject.subject_uri, RDF::DC.title, 'moomin')
          expect { subject.request(:PUT, 200, {'abc' => 'def'}, env) }
            .to change { subject.graph.statements.count }.to(1)
        end

        it 'updates the etag' do
          graph << RDF::Statement(subject.subject_uri, RDF::DC.title, 'moomin')
          expect { subject.request(:PUT, 200, {'abc' => 'def'}, env) }
            .to change { subject.etag }
        end

        it 'returns the etag' do
          expect(subject.request(:PUT, 200, {'abc' => 'def'}, env)[1]['ETag'])
            .to eq subject.etag
        end

        it 'gives PreconditionFailed when trying to update with wrong Etag' do
          env['HTTP_IF_MATCH'] = 'not an Etag'
          expect { subject.request(:PUT, 200, {'abc' => 'def'}, env) }
            .to raise_error RDF::LDP::PreconditionFailed
        end

        it 'succeeds when giving correct Etag' do
          graph << RDF::Statement(subject.subject_uri, RDF::DC.title, 'moomin')
          env['HTTP_IF_MATCH'] = subject.etag
          expect { subject.request(:PUT, 200, { 'abc' => 'def' }, env) }
            .to change { subject.graph.statements.count }
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

  describe '#containment_triples' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'returns a uri' do
      subject.add_containment_triple(resource)
      expect(subject.containment_triples)
        .to contain_exactly(an_instance_of(RDF::Statement))
    end
  end

  describe '#add' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }
    before { subject.create('', 'text/plain') }

    it 'returns self' do
      expect(subject.add(resource)).to eq subject
    end

    it 'containment triple is added to graph' do
      expect(subject.add(resource).graph)
        .to include subject.make_containment_triple(resource)
    end
  end

  describe '#add_containment_triple' do
    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'returns self' do
      expect(subject.add_containment_triple(resource)).to eq subject
    end

    it 'containment triple is added to graph' do
      expect(subject.add_containment_triple(resource).graph)
        .to include subject.make_containment_triple(resource)
    end
  end

  describe '#remove_containment_triple' do
    before { subject.add_containment_triple(resource) }

    let(:resource) { RDF::URI('http://ex.org/mymble') }

    it 'returns self' do
      expect(subject.remove_containment_triple(resource)).to eq subject
    end

    it 'membership triple is added to graph' do
      expect(subject.remove_containment_triple(resource).graph)
        .not_to include subject.make_containment_triple(resource)
    end
  end

  describe '#make_containment_triple' do
    let(:resource) { uri / 'papa' }

    it 'returns a statement' do
      expect(subject.make_containment_triple(resource)).to be_a RDF::Statement
    end

    it 'statement subject *or* object is #subject_uri' do
      sub = subject.make_containment_triple(resource).subject
      obj = subject.make_containment_triple(resource).object
      expect([sub, obj]).to include subject.subject_uri
    end

    it 'converts Resource classes to URI' do
      sub = subject.make_containment_triple(subject).subject
      obj = subject.make_containment_triple(subject).object
      expect([sub, obj]).to include subject.subject_uri
    end
  end

  describe '#request' do
    context 'with :PUT',
            if: described_class.private_method_defined?(:put) do
      let(:graph) { RDF::Graph.new }

      let(:env) do
        { 'rack.input' => StringIO.new(graph.dump(:ntriples)),
          'CONTENT_TYPE' => 'text/plain' }
      end
      
      context 'when PUTing containment triples' do
        let(:statement) do
          RDF::Statement(subject.subject_uri,
                         RDF::Vocab::LDP.contains,
                         'moomin')
        end

        it 'when creating a resource raises a Conflict error' do
          graph << statement
          expect { subject.request(:PUT, 200, {'abc' => 'def'}, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'when resource exists raises a Conflict error' do
          subject.create('', 'text/plain')
          graph << statement
          expect { subject.request(:PUT, 200, {'abc' => 'def'}, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'can put existing containment triple' do
          subject.create('', 'text/plain')
          subject.graph << statement
          graph << statement
          expect(subject.request(:PUT, 200, {'abc' => 'def'}, env).first)
            .to eq 200
        end

        it 'writes data when putting existing containment triple' do
          subject.create('', 'text/plain')
          subject.graph << statement
          graph << statement
          
          new_st = RDF::Statement(RDF::URI('http://example.org/new_moomin'), 
                                  RDF::DC.title, 
                                  'moomin')
          graph << new_st
          expect(subject.request(:PUT, 200, {'abc' => 'def'}, env).last.graph)
            .to have_statement new_st
        end

        it 'raises conflict error when without existing containment triples' do
          subject.create('', 'text/plain')
          subject.graph << statement
          expect { subject.request(:PUT, 200, {'abc' => 'def'}, env) }
            .to raise_error RDF::LDP::Conflict
        end
      end
    end

    context 'when POST is implemented', 
            if: described_class.private_method_defined?(:post) do
      let(:graph) { RDF::Graph.new }
      before { subject.create('', 'text/plain') }

      let(:env) do
        { 'rack.input' => StringIO.new(graph.dump(:ntriples)),
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

      it 'adds containment statement to resource' do
        expect { subject.request(:POST, 200, {}, env) }
          .to change { subject.containment_triples.count }.from(0).to(1)
      end

      context 'with Container interaction model' do
        it 'creates a basic container' do
          env['HTTP_LINK'] = "<#{RDF::LDP::Container.to_uri}>;rel=\"type\""
          expect(subject.request(:POST, 200, {}, env).last)
            .to be_a RDF::LDP::Container
        end

        context 'BasicContainer' do
          it 'creates a basic container' do
            env['HTTP_LINK'] = 
              "<http://www.w3.org/ns/ldp#BasicContainer>;rel=\"type\""
            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::Container
          end
        end

        context 'DirectContainer' do
          it 'creates a direct container' do
            env['HTTP_LINK'] = "<#{RDF::LDP::DirectContainer.to_uri}>;rel=\"type\""
            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::DirectContainer
          end
        end

        context 'IndirectContainer' do
          it 'creates a indirect container' do
            env['HTTP_LINK'] = "<#{RDF::LDP::IndirectContainer.to_uri}>;rel=\"type\""
            expect(subject.request(:POST, 200, {}, env).last)
              .to be_a RDF::LDP::IndirectContainer
          end
        end
      end

      context 'with a Slug' do
        it 'creates resource with Slug' do
          env['HTTP_SLUG'] = 'snork'
          expect(subject.request(:POST, 200, {}, env).last.subject_uri)
            .to eq (subject.subject_uri / env['HTTP_SLUG'])
        end

        it 'mints a uri when empty Slug is given' do
          env['HTTP_SLUG'] = ''
          expect(subject.request(:POST, 200, {}, env).last.subject_uri)
            .to be_starts_with (subject.subject_uri)
        end

        it 'raises a 409 Conflict when slug is already taken' do
          env['HTTP_SLUG'] = 'snork'
          subject.request(:POST, 200, {}, env)

          expect { subject.request(:POST, 200, {}, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'raises a 409 Conflict when slug is already taken but destroyed' do
          env['HTTP_SLUG'] = 'snork'
          created = subject.request(:POST, 200, {}, env).last
          allow(created).to receive(:destroyed?).and_return true
          
          expect { subject.request(:POST, 200, {}, env) }
            .to raise_error RDF::LDP::Conflict
        end

        it 'raises a 406 NotAcceptable if slug has a uri fragment `#`' do
          env['HTTP_SLUG'] = 'snork#maiden'

          expect { subject.request(:POST, 200, {}, env) }
            .to raise_error RDF::LDP::NotAcceptable
        end

        it 'url-encodes Slug' do
          env['HTTP_SLUG'] = 'snork maiden'
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
            { 'rack.input' => StringIO.new(graph.dump(:nquads)),
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

# @todo: make this set of examples less opinionated about #add behavior.
#   Break #add tests into another group shared between DirectContainer & 
#   IndirectContainer. This way other implementations can use these specs
#   but make different intrepretations of loose parts in the LDP spec.
shared_examples 'a DirectContainer' do
  it_behaves_like 'a Container'

  let(:uri) { RDF::URI('http://ex.org/moomin') }
  subject { described_class.new(uri) }

  let(:has_member_statement) do
    RDF::Statement(subject.subject_uri, 
                   RDF::Vocab::LDP.hasMemberRelation, 
                   RDF::DC.hasPart)
  end

  let(:is_member_of_statement) do
    RDF::Statement(subject.subject_uri, 
                   RDF::Vocab::LDP.isMemberOfRelation, 
                   RDF::DC.isPartOf)
  end

  describe '#add' do
    let(:resource_uri) { RDF::URI('http://ex.org/too-ticky') }

    it 'raises an error if the membership resource does not exist' do
      expect { subject.add(resource_uri) }
        .to raise_error RDF::LDP::NotAcceptable
      expect(subject.containment_triples).to be_empty
    end

    context 'when the membership resource exists' do
      before { subject.create('', 'text/plain') }

      it 'adds membership triple to membership resource' do
        expect(subject.add(resource_uri).graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      it 'adds membership triple to custom membership resource' do
        repo = RDF::Repository.new
        subject = described_class.new(uri, repo)
        mem_rs = RDF::LDP::RDFSource.new(RDF::URI('http://ex.org/mymble'), 
                                         repo)

        subject.create('', 'text/plain')
        mem_rs.create('', 'text/plain')
        
        subject.graph << RDF::Statement(subject.subject_uri,
                                        RDF::Vocab::LDP.membershipResource,
                                        mem_rs.subject_uri)

        subject.add(resource_uri)

        expect(mem_rs.graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      it 'adds membership triple to membership resource with #fragment' do
        mem_rs = subject.subject_uri / '#membership'
        subject.graph << RDF::Statement(subject.subject_uri,
                                        RDF::Vocab::LDP.membershipResource,
                                        mem_rs)
        expect(subject.add(resource_uri).graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      it 'adds membership triple to LDP-NR membership resource' do
        repo = RDF::Repository.new
        container = described_class.new(uri, repo)
        nr = RDF::LDP::NonRDFSource.new('http://example.org/moomin_file',
                                        repo)
        nr.create(StringIO.new(''), 'text/plain')
        container.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.membershipResource,
                                          nr.to_uri)

        container.add(resource_uri)
        expect(nr.description.graph)
          .to have_statement container.make_membership_triple(resource_uri)
      end

      context 'with multiple membership resources' do
        it 'raises an error' do
          subject.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.membershipResource,
                                          subject.subject_uri)
          subject.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.membershipResource,
                                          (subject.subject_uri / 'moomin'))

          expect { subject.add(resource_uri) }
            .to raise_error RDF::LDP::RequestError
          expect(subject.containment_triples).to be_empty
        end
      end
    end
  end

  describe '#remove' do
    let(:resource_uri) { RDF::URI('http://ex.org/too-ticky') }

    it 'raises an error if the membership resource does not exist' do
      expect { subject.remove(resource_uri) }
        .to raise_error RDF::LDP::NotAcceptable
    end

    context 'when the membership resource exists' do
      before { subject.create('', 'text/plain') }

      it 'removes membership triple to membership resource' do
        subject.graph << subject.make_membership_triple(resource_uri)
        expect(subject.remove(resource_uri).graph)
          .not_to have_statement subject.make_membership_triple(resource_uri)
      end
    end

  end

  describe '#membership_constant_uri' do
    it 'defaults to #subject_uri' do
      expect(subject.membership_constant_uri).to eq subject.subject_uri
      expect(subject.graph)
        .to have_statement RDF::Statement(subject.subject_uri, 
                                          RDF::Vocab::LDP.membershipResource, 
                                          subject.subject_uri)
    end

    it 'gives membership resource' do
      membership_resource = (subject.subject_uri / '#too-ticky')
      subject.graph << RDF::Statement(subject.subject_uri, 
                                      RDF::Vocab::LDP.membershipResource, 
                                      membership_resource)
      expect(subject.membership_constant_uri).to eq membership_resource
    end

    it 'raises an error if multiple are present' do
      membership_resource = (subject.subject_uri / '#too-ticky')
      subject.graph << RDF::Statement(subject.subject_uri, 
                                      RDF::Vocab::LDP.membershipResource, 
                                      membership_resource)

      subject.graph << RDF::Statement(subject.subject_uri, 
                                      RDF::Vocab::LDP.membershipResource, 
                                      subject.subject_uri)

      expect { subject.membership_constant_uri }
        .to raise_error RDF::LDP::RequestError
    end
  end

  describe '#membership_predicate' do
    it 'returns a uri' do
      expect(subject.membership_predicate).to be_a RDF::URI
    end

    it 'gives assigned member relation predicate for hasMember' do
      subject.graph << has_member_statement

      expect(subject.membership_predicate).to eq RDF::DC.hasPart
    end

    it 'gives assigned member relation predicate for isMemberOf' do
      subject.graph << is_member_of_statement

      expect(subject.membership_predicate).to eq RDF::DC.isPartOf
    end

    it 'raises an error if multiple relation predicates are present' do
      subject.graph << has_member_statement
      subject.graph << is_member_of_statement

      expect { subject.membership_predicate }
        .to raise_error RDF::LDP::RequestError
    end
  end

  describe '#make_membership_triple' do
    context 'with hasMember' do
      before { subject.graph << has_member_statement }

      it 'is constant - predicate - derived' do
        expect(subject.make_membership_triple(uri))
          .to eq RDF::Statement(subject.membership_constant_uri, 
                                subject.membership_predicate, 
                                uri)
      end
    end

    context 'with isMemberOf' do
      before { subject.graph << is_member_of_statement }

      it 'is derived - predicate - constant' do
        expect(subject.make_membership_triple(uri))
          .to eq RDF::Statement(uri,
                                subject.membership_predicate, 
                                subject.membership_constant_uri)
      end
    end
  end
end

shared_examples 'an IndirectContainer' do
  it_behaves_like 'a DirectContainer'  

  shared_context 'with a relation' do
    before { subject.graph << inserted_content_statement }

    let(:relation_predicate) { RDF::DC.creator }

    let(:inserted_content_statement) do
      RDF::Statement(subject.subject_uri, 
                     RDF::Vocab::LDP.indirectContentRelation,
                     relation_predicate)
    end
  end
  
  describe '#inserted_content_relation' do
    it 'returns a uri' do
      expect(subject.inserted_content_relation).to be_a RDF::URI
    end

    context 'with a relation' do
      include_context 'with a relation'

      it 'gives the relation' do
        expect(subject.inserted_content_relation).to eq relation_predicate
      end

      it 'raises an error when more than one exists' do
        new_statement = inserted_content_statement.clone
        new_statement.object = RDF::DC.relation
        subject.graph << new_statement
        expect { subject.inserted_content_relation }
          .to raise_error RDF::LDP::NotAcceptable
      end
    end
  end

  describe '#add' do
    include_context 'with a relation'

    subject { described_class.new(uri, repo) }

    let(:repo) { RDF::Repository.new }
    let(:resource_uri) { RDF::URI('http://example.org/too-ticky') }
    let(:contained_resource) { RDF::LDP::RDFSource.new(resource_uri, repo) }
    
    context 'when no derived URI is found' do
      it 'raises NotAcceptable' do
        expect { subject.add(contained_resource) }
          .to raise_error RDF::LDP::NotAcceptable
      end

      it 'does not create the resource' do
        begin; subject.add(contained_resource); rescue; end
        expect(contained_resource).not_to exist
      end
    end

    context 'with expected predicate' do
      before { contained_resource.graph << statement }

      let(:target_uri) { contained_resource.to_uri / '#me' }

      let(:statement) do
        RDF::Statement(contained_resource.to_uri, 
                       relation_predicate, 
                       target_uri)
      end
      
      it 'when membership resource does not exist raises NotAcceptable' do
        expect { subject.add(contained_resource) }
          .to raise_error RDF::LDP::NotAcceptable
      end

      context 'when the container exists' do
        before { subject.create('', 'text/plain') }

        it 'adds membership triple' do
          subject.add(contained_resource)
          expect(subject.graph.statements)
            .to include RDF::Statement(subject.to_uri,
                                       subject.membership_predicate,
                                       target_uri)
        end

        it 'for multiple predicates raises NotAcceptable' do
          new_statement = statement.clone
          new_statement.object = contained_resource.to_uri / '#you'
          contained_resource.graph << new_statement
          expect { subject.add(contained_resource) }
            .to raise_error RDF::LDP::NotAcceptable
        end

        it 'for an LDP-NR raises NotAcceptable' do
          nr_resource = RDF::LDP::NonRDFSource.new(resource_uri, repo)
          expect { subject.add(nr_resource) }
            .to raise_error RDF::LDP::NotAcceptable
        end
      
        context 'with membership resource' do
          before do
            subject.graph << RDF::Statement(subject.to_uri,
                                            RDF::Vocab::LDP.membershipResource,
                                            contained_resource.to_uri)
          end
          
          it 'raises error when resource does not exist' do
            expect { subject.add(contained_resource) }
              .to raise_error RDF::LDP::NotAcceptable
          end

          it 'adds triple to membership resource' do
            contained_resource.create('', 'text/plain')
            subject.add(contained_resource)
            expect(contained_resource.graph.statements)
              .to include RDF::Statement(contained_resource.to_uri,
                                         subject.membership_predicate,
                                         target_uri)
          end

          it 'removes triple from membership resource' do
            contained_resource.create('', 'text/plain')
            subject.add(contained_resource)
            subject.remove(contained_resource)
            expect(contained_resource.graph.statements)
              .not_to include RDF::Statement(contained_resource.to_uri,
                                             subject.membership_predicate,
                                             target_uri)
          end
        end
      end
    end
  end
end
