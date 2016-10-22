shared_examples 'a memento timemap' do
  describe '#memento_original' do
    it 'returns an RDF::URI' do
      expect(subject.memento_original).to eq original
    end
  end

  describe '#to_uri' do
    it 'returns an RDF::URI' do
      expect(subject.to_uri).to eq uri
    end
  end

  describe '#to_s' do
    it 'gives string form of #to_uri' do
      expect(subject.to_s).to eq subject.to_uri.to_s
    end
  end
end
