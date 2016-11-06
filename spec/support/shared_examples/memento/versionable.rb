shared_examples 'a versionable LDP-R' do

  describe '#create_version' do
    it 'adds a version' do
      expect { subject.create_version }
        .to change { subject.versions.count }.by(1)
    end
  end
  
  describe '#timegate' do
    it 'defaults to self' do
      expect(subject.timegate).to equal subject
    end
  end

  describe '#timemap' do
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
