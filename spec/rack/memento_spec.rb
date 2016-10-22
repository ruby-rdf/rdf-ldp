# coding: utf-8
require 'rack/memento'
require 'rack/test'

describe Rack::Memento do
  include ::Rack::Test::Methods

  subject { described_class.new(base_app) }

  let(:app)      { subject }
  let(:body)     { 'A Response Body' }
  let(:response) { [body] }
  let(:headers)  { {} }

  let(:base_app) do
    double("Target Rack Application",
           :call => [200, headers, response])
  end

  describe 'link relations' do
    ['original', 'timegate', 'timemap', 'memento'].each do |rel|
      it "has #{rel} relation" do
        expect(Object.const_get("#{described_class.name}::#{rel.upcase}_REL"))
          .to eq rel
      end
    end
  end

  describe '#call' do
    context 'with no timegate/timemap' do
      it 'passes through for resources' do
        get '/'
        expect(last_response.body).to eq body
      end
    end
    
    context 'when the resource has a timemap' do
      let(:uri_t)    { 'http://example.org/URI-T' }
      let(:response) { double('URI-R', timemap: uri_t, each: body) }

      it 'adds timemap Link header' do
        get '/'
        expect(last_response.headers['Link'])
          .to eq "<#{uri_t}>;rel=#{described_class::TIMEMAP_REL}"
      end

      it 'keeps other link headers' do
        link = '<fake.rdf>;rel=meta'
        headers['Link'] = link

        get '/'
        expect(last_response.headers['Link']).to include link
        expect(last_response.headers['Link'])
          .to include "<#{uri_t}>;rel=#{described_class::TIMEMAP_REL}"
      end
    end

    context 'when the resource has a timegate' do
      let(:uri_g)    { 'http://example.org/URI-G' }
      let(:response) { double('URI-R', timegate: uri_g, each: body) }

      it 'adds timegate Link header' do
        get '/'
        expect(last_response.headers['Link'])
          .to eq "<#{uri_g}>;rel=#{described_class::TIMEGATE_REL}"
      end

      it 'keeps other link headers' do
        link = '<fake.rdf>;rel=meta'
        headers['Link'] = link

        get '/'
        expect(last_response.headers['Link']).to include link
        expect(last_response.headers['Link'])
          .to include "<#{uri_g}>;rel=#{described_class::TIMEGATE_REL}"
      end
    end
  end
end
