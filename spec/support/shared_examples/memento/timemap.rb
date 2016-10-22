shared_examples 'a memento timemap' do
  describe '#memento_original' do
    it 'returns an RDF::URI' do
      expect(subject.memento_original).to eq original
    end
  end

  describe '#memento_versions' do
    it 'returns an enumerable' do
      expect(subject.memento_versions).to respond_to :each
    end

    it 'enumerates version uris' do
      expect(subject.memento_versions)
        .to satisfy { |enum| enum.all? { |i| i.is_a? RDF::URI } }
    end
  end

  describe '#to_s' do
    it 'gives string form of #to_uri' do
      expect(subject.to_s).to eq subject.to_uri.to_s
    end
  end

  describe '#to_uri' do
    it 'returns an RDF::URI' do
      expect(subject.to_uri).to eq uri
    end
  end
end
