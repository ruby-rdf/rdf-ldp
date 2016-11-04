shared_examples 'a memento timemap' do
  describe '#link_format' do
    it 'returns a rack body' do
      expect { |b| subject.link_format.each(&b) }
        .to yield_with_args(an_instance_of(String))
    end
    
    it 'includes original in link-format' do
      expect(subject.link_format.each.first)
        .to include "<#{subject.memento_original}>;rel=\"original\""
    end

    it 'includes timegate in link-format' do
      expect(subject.link_format.each.first)
        .to include "<#{subject.memento_timegate}>;rel=\"timegate\""
    end

    it 'includes timegate in link-format' do
      allow(subject).to receive(:memento_timegate).and_return(nil)
      expect(subject.link_format.each.first).not_to include "rel=\"timegate\""
    end
  end
  
  describe '#memento_original' do
    it 'returns an RDF::URI' do
      expect(subject.memento_original).to eq original
    end
  end

  describe '#memento_timegate' do
    it 'returns an RDF::URI' do
      expect(subject.memento_timegate).to eq timegate
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
