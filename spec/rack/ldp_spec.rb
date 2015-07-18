require 'rack/ldp'
require 'rack/test'

describe Rack::LDP do
  it 'has MIME types from Rack::LinkedData' do
    expect(Rack::Mime::MIME_TYPES).to have_key '.ntriples'
  end
end

describe Rack::LDP::Headers do
  include ::Rack::Test::Methods

  subject { described_class.new(base_app) }

  let(:headers) do
    { 'Link' => '<http://example.org/ns/moomin>;rel="derivedfrom"' }
  end

  let(:results) { ['A Response'] }

  let(:base_app) do
    double("Target Rack Application", 
           :call => [200, headers, results])
  end

  let(:app) { subject }

  it 'retains existing Link headers' do
    get '/'
    expect(last_response.header['Link']).to include headers['Link']
  end

  context 'when response responds to #to_response' do
    before { allow(results).to receive(:to_response).and_return([body]) }
    let(:body) { 'new body' }
    
    it 'closes response' do
      expect(results).to receive(:close)
      get '/'
    end

    it 'returns the new response' do
      get '/'
      expect(last_response.body).to eq body
    end
  end

  context 'when response responds to #etag' do
    it 'adds an Etag header' do
      etag = double('etag')
      allow(results).to receive(:etag).and_return(etag)

      get '/'
      expect(last_response.header['Etag']).to eq etag
    end

    it 'has no Etag header if #etag is `nil`' do
      allow(results).to receive(:etag).and_return(nil)

      get '/'
      expect(last_response.header).not_to include 'Etag'
    end
  end

  context 'when response is a Resource' do
    before { allow(results).to receive(:to_response).and_return([]) }

    let(:resource) { RDF::LDP::Resource.new }
    let(:results) { resource }

    it 'retains existing Link headers' do
      get '/'
      expect(last_response.header['Link']).to include headers['Link']
    end

    it 'adds LDPR Link header' do
      get '/'
      expect(last_response.header['Link'])
        .to include Rack::LDP::Headers::LINK_LDPR
    end

    context 'and an RDFSource' do
      let(:resource) { RDF::LDP::RDFSource.new }

      it 'adds LDPRS Link header' do
        get '/'
        expect(last_response.header['Link'])
          .to include Rack::LDP::Headers::LINK_LDPR
        expect(last_response.header['Link'])
          .to include Rack::LDP::Headers::LINK_LDPRS
      end
    end

    context 'and an RDFSource' do
      let(:resource) { RDF::LDP::NonRDFSource.new }

      it 'adds LDPNR Link header' do
        get '/'
        expect(last_response.header['Link'])
          .to include Rack::LDP::Headers::LINK_LDPR
        expect(last_response.header['Link'])
          .to include Rack::LDP::Headers::LINK_LDPNR
      end
    end
  end
end

describe Rack::LDP::ContentNegotiation do
  subject { described_class.new(app) }
  let(:app) { double('rack application') }

  it { is_expected.to be_a Rack::LinkedData::ContentNegotiation }

  describe '.new' do
    it 'sets default content-type to text/turtle' do
      expect(subject.options[:default]).to eq 'text/turtle'
    end

    it 'accepts overrides to default content type' do
      ctype = 'text/plain'
      conneg = described_class.new(app, default: ctype)
      expect(conneg.options[:default]).to eq ctype
    end
  end
end
