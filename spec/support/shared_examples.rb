
shared_examples 'a Resource' do
  describe '.to_uri' do
    it { expect(described_class.to_uri).to be_a RDF::URI }
  end

  it { is_expected.to be_ldp_resource }
  it { is_expected.to respond_to :container? }
  it { is_expected.to respond_to :rdf_source? }
  it { is_expected.to respond_to :non_rdf_source? }
end

shared_examples 'an RDFSource' do
  it_behaves_like 'a Resource'

  it { is_expected.to be_rdf_source }
  it { is_expected.not_to be_non_rdf_source }

  describe '#etag' do
    before do
      subject.graph << statement
      other.graph << statement
    end

    let(:other) { described_class.new }

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

  describe '#graph' do
    it 'has a graph' do
      expect(subject.graph).to be_a RDF::Enumerable
    end
  end

  describe '#to_response' do
    it 'defaults to :GET' do
      expect(subject.to_response).to eq subject.to_response(:GET)
    end

    context 'with :GET' do
      it 'gives the graph' do
        expect(subject.to_response(:GET)).to eq subject.graph
      end
    end
  end
end

shared_examples 'a Container' do
  it_behaves_like 'an RDFSource'

  it { is_expected.to be_container }

  describe '#container_class' do
    it 'returns a uri' do
      expect(subject.container_class).to be_a RDF::URI
    end
  end
end


