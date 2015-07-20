require 'rack/ldp'
require 'rack/test'

describe Rack::LDP do
  it 'has MIME types from Rack::LinkedData' do
    expect(Rack::Mime::MIME_TYPES).to have_key '.ntriples'
  end
end

describe 'middleware' do
  include ::Rack::Test::Methods

  before do
    ##
    # Dummy response handler middleware
    class ToResponseHandler
      def initialize(app); @app = app; end
      
      def call(env)
        status, headers, response = @app.call(env)
        response = response.to_response if response.respond_to? :to_response
        [status, headers, response]
      end
    end
    
    allow(results).to receive(:to_response).and_return([])
  end

  after { Object.send(:remove_const, 'ToResponseHandler') }

  let(:results) { ['A Response'] }
  let(:headers) { {} }

  let(:base_app) do
    double("Target Rack Application", 
           :call => [200, headers, results])
  end

  let(:app) { ToResponseHandler.new(subject) }

  describe Rack::LDP::Errors do
    subject { described_class.new(base_app) }

    it 'catches RequestErrors' do
      msg = 'hibernating'
      err = RDF::LDP::RequestError.new(msg)
      allow(base_app).to receive(:call).with(any_args).and_raise(err)

      get '/'
      expect(last_response).to have_attributes(status: err.status,
                                               body: err.message)
    end
  end

  describe Rack::LDP::Responses do
    before do
      allow(results)
        .to receive(:to_response).and_return([body])
    end

    subject { described_class.new(base_app) }
    let(:app) { subject }

    let(:body) { 'new body' }
    let(:method) { :GET }
    
    context 'when response is not an LDP::Resource' do
      it 'echo it back unaltered' do
        get '/'
        expect(last_response.body).to eq results.first
      end
    end

    context 'when response responds to #to_response' do
      let(:resource) { RDF::LDP::Resource.new }
      let(:results) { resource }

      it 'closes response' do
        expect(results).to receive(:close)
        get '/'
      end

      it 'returns the new response' do
        expect(results)
          .to receive(:to_response).and_return([body])
        get '/'
        expect(last_response.body).to eq body
      end
    end
  end

  describe Rack::LDP::Requests do
    subject { described_class.new(base_app) }

    let(:resource) { RDF::LDP::Resource.new }
    let(:results) { resource }

    it 'sends the request message' do
      methods = [:GET, :POST, :PUT, :DELETE, :PATCH, :OPTIONS]

      methods.each do |m|
        expect(results)
          .to receive(:request).with(m, any_args).and_return([200, {}, []])
        send(m.downcase, '/')
      end
    end
  end

  describe Rack::LDP::Headers do
    subject { described_class.new(base_app) }
  
    let(:headers) do
      { 'Link' => '<http://example.org/ns/moomin>;rel="derivedfrom"' }
    end

    it 'retains existing Link headers' do
      get '/'
      expect(last_response.header['Link']).to include headers['Link']
    end

    context 'when response responds to #etag' do
      let(:resource) { RDF::LDP::Resource.new }
      let(:results) { resource }

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

      context 'and a Container' do
        let(:resource) { RDF::LDP::Container.new }

        it 'adds LDPC Link header' do
          get '/'
          expect(last_response.header['Link'])
            .to include Rack::LDP::Headers::LINK_LDPR
          expect(last_response.header['Link'])
            .to include Rack::LDP::Headers::LINK_LDPRS
          expect(last_response.header['Link'])
            .to include "<#{resource.container_class}>;rel=\"type\""
        end
      end

      context 'and a NonRDFSource' do
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
end
