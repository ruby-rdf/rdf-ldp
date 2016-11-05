shared_examples 'a versionable LDP-R' do
  describe '#timegate' do
    it 'defaults to self' do
      expect(subject.timegate).to equal subject
    end
  end

  describe '#timemap' do
    it 'has an original' do
      expect(subject.timemap).to respond_to :memento_original
    end

    it 'has a timegate' do
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
end
