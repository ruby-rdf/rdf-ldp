require 'spec_helper'

require 'rdf/ldp/memento/version_container'

describe RDF::LDP::Memento::VersionContainer do
  subject        { described_class.new(uri) }
  let(:uri)      { RDF::URI('http://example.org/moomin/.well-known/timemap') }
  let(:original) { RDF::URI('http://example.org/moomin/') }
  let(:timegate) { RDF::URI('http://example.org/moomin/.well-known/timegate') }

  before do
    subject.memento_original = original
    subject.memento_timegate = timegate
  end
  
  it_behaves_like 'a memento timemap'
  it_behaves_like 'a Container'

  describe '#memento_versions' do
    it 'is empty by default' do
      expect(subject.memento_versions).to be_empty
    end

    context 'with contained resources' do
      let(:version_uris) { (1..5).map { |i| original / i} }

      before { version_uris.each { |uri| subject.add(uri) } }

      it 'enumerates over the version uris' do
        expect(subject.memento_versions).to contain_exactly(*version_uris)
      end
    end
  end
end
