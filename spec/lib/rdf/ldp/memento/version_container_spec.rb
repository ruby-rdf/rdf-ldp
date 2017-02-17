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
  it_behaves_like 'a DirectContainer'

  describe '#add' do
    # we need to create the container to add anything; this is required by the
    # LDP::DirectContainer interface.
    before { subject.create(StringIO.new, 'text/plain') }

    context 'with a URI' do
      let(:version) { RDF::URI('http://example.com/my_version') }

      it 'adds the version' do
        expect { subject.add(version) }
          .to change { subject.memento_versions }
                .to contain_exactly(version)
      end
    end

    context 'with an RDFSource' do
      let(:version) do
        RDF::LDP::RDFSource.new(RDF::URI('http://example.com/my_version'))
      end

      it 'adds the version' do
        expect { subject.add(version) }
          .to change { subject.memento_versions }
                .to contain_exactly(version.to_uri)
      end
    end

    context 'with a NonRDFSource' do
      let(:version) do
        RDF::LDP::NonRDFSource.new(RDF::URI('http://example.com/my_version'))
      end

      it 'adds the version' do
        expect { subject.add(version) }
          .to change { subject.memento_versions }
                .to contain_exactly(version.to_uri)
      end
    end
  end

  describe '#memento_versions' do
    it 'is empty by default' do
      expect(subject.memento_versions).to be_empty
    end

    context 'with contained resources' do
      let(:version_uris) { (1..5).map { |i| original / i} }

      before do
        subject.create(StringIO.new, 'text/plain')
        version_uris.each { |uri| subject.add(uri) }
      end

      it 'enumerates over the version uris' do
        expect(subject.memento_versions).to contain_exactly(*version_uris)
      end
    end
  end

  context 'when reloaded' do
    subject do
      data = RDF::Repository.new

      sub = described_class.new(uri, data)
      sub.memento_original = original
      sub.memento_timegate = timegate

      sub.create(StringIO.new, 'text/plain')

      RDF::LDP::Resource.find(uri, data)
    end

    it_behaves_like 'a memento timemap'
  end
end
