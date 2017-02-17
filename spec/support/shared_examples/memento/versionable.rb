shared_examples 'a versionable LDP-R' do
  describe '#create_version' do
    it 'adds a version' do
      expect { subject.create_version }
        .to change { subject.versions.count }.by(1)
    end

    it 'returns a version of the resource' do
      version = subject.create_version

      expect(subject.timemap.graph)
        .to have_statement(
              RDF::Statement(version.to_uri,
                             RDF::Vocab::PROV.wasRevisionOf,
                             subject.to_uri,
                             graph_name: subject.timemap.graph.graph_name))
    end

    it 'returns a new version of the resource' do
      version = subject.create_version
      created = subject.timemap.graph.query(subject:   version.to_uri,
                                            predicate: RDF::Vocab::DC.created)
      datetime = created.first.object.object

      expect(datetime).to be_within(0.00001).of DateTime.now
    end

    it 'accepts a custom datetime' do
      target_time = DateTime.now - 1
      version = subject.create_version(datetime: target_time)
      created = subject.timemap.graph.query(subject:   version.to_uri,
                                            predicate: RDF::Vocab::DC.created)
      datetime = created.first.object.object

      expect(datetime).to eq target_time
    end

    it 'raises an ArgumentError when datetime is in the future' do
      target_time = DateTime.now + 1

      expect { subject.create_version(datetime: target_time) }
        .to raise_error ArgumentError
    end

    context 'with an LDP-RS' do
      let(:resource_class) do
        Class.new(RDF::LDP::RDFSource) do
          include RDF::LDP::Memento::Versionable
        end
      end

      let(:triples) { RDF::Spec.triples }

      before { subject.graph.insert(*triples) }

      it 'returns a version with current resource contents' do
        expect(subject.create_version.graph).to include(*triples)
      end
    end
  end

  describe '#timegate' do
    it 'defaults to self' do
      expect(subject.timegate).to equal subject
    end
  end

  describe '#timemap' do
    it 'exists' do
      expect(subject.timemap).to exist
    end

    it 'has an original' do
      expect(subject.timemap).to respond_to :memento_original
    end

    it' has a timegate' do
      expect(subject.timemap).to respond_to :memento_timegate
    end

    it 'has a link-format response' do
      expect(subject.timemap).to respond_to :link_format
    end

    it 'has a uri' do
      expect(subject.timemap).to respond_to :to_uri
    end

    it 'shares a uri with #timemap_uri' do
      expect(subject.timemap.to_uri).to eq subject.timemap_uri
    end
  end

  describe '#versions' do
    it 'returns an enumerable' do
      expect(subject.versions).to respond_to :each
    end

    context 'with versions' do
      it 'versions share uris with those listed by the timemap' do
        expect(subject.versions.map(&:to_uri))
          .to contain_exactly(*subject.timemap.memento_versions)
      end
    end
  end
end
