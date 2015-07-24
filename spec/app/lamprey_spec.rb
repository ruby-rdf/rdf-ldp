require 'spec_helper'
require 'rack/test'

require 'lamprey'

describe 'lamprey' do
  include ::Rack::Test::Methods
  let(:app) { Sinatra::Application }
  
  describe 'base container /' do 
    describe 'GET' do
      it 'has default content type "text/turtle"' do
        get '/'
        expect(last_response.header['Content-Type']).to eq 'text/turtle'
      end

      it 'has an Etag' do
        get '/'
        expect(last_response.header['Etag']).to be_a String
      end
      
      context 'when resource exists' do
        let(:graph) { RDF::Graph.new }

        before do
          graph << RDF::Statement(RDF::URI('http://example.org/moomin'), 
                                  RDF::DC.title,
                                  'mummi')
          
          graph_str = graph.dump(:ntriples)

          post '/', graph_str, 'CONTENT_TYPE' => 'text/plain'
          @uri = last_response.header['Location']
        end
        
        it 'can get the resource' do
          get @uri
          returned = RDF::Reader.for(:ttl).new(last_response.body).statements.to_a

          graph.statements.each do |s|
            expect(returned).to include s
          end
        end

        it 'is not a container' do
          get @uri
          expect(last_response.header['Link'])
            .not_to include 'http://www.w3.org/ns/ldp#BasicContainer'
        end
      end
    end

    describe 'OPTIONS' do
      it 'has Allow headers' do
        options '/'
        expect(last_response.header['Allow'])
          .to include('GET', 'POST', 'OPTIONS', 'HEAD')
      end

      it 'has Accept-Post headers' do
        options '/'
        expect(last_response['Accept-Post']).to include 'text/turtle'
      end

      context 'existing resource' do
        before do
          post '/', '', 'CONTENT_TYPE' => 'text/plain', 'Slug' => 'moomin'
        end

        it 'has Allow for resource type' do
          options '/'
          expect(last_response.header['Allow'])
            .to include('GET', 'OPTIONS', 'HEAD')
        end
      end
    end

    describe 'POST' do
      let(:graph) { RDF::Graph.new }

      before do
        graph << RDF::Statement(RDF::URI('http://example.org/moomin'), 
                                RDF::DC.title,
                                'mummi')
      end

      it 'gives a 201 status code' do
        post '/', graph.dump(:ttl), 'CONTENT_TYPE' => 'text/plain'
        expect(last_response.status).to eq 201
      end

      it 'gives an ETag for the new resource' do
        post '/', graph.dump(:ttl), 'CONTENT_TYPE' => 'text/plain'
        expect(last_response.status).to eq 201
      end

      it 'responds with the graph' do
        graph_str = graph.dump(:ntriples)
        post '/', graph_str, 'CONTENT_TYPE' => 'text/plain'
        returned = RDF::Reader.for(:ttl).new(last_response.body).statements.to_a

        graph.statements.each do |s|
          expect(returned).to include s
        end
      end

      it 'gives a location header' do
        post '/', graph.dump(:ttl), 'CONTENT_TYPE' => 'text/plain'
        expect(last_response.header['Location'])
          .to start_with 'http://example.org/'
      end

      context 'with Slug' do
        it 'accepts a Slug' do
          post '/', graph.dump(:ttl), 
               'CONTENT_TYPE' => 'text/plain', 
               'Slug' => 'moominpapa'
          expect(last_response.header['Location'])
            .to eq 'http://example.org/moominpapa'
        end

        it 'rejects slugs with #' do
          post '/', graph.dump(:ttl), 
               'CONTENT_TYPE' => 'text/plain', 
               'Slug' => 'moomin#papa'
          expect(last_response.status).to eq 406
        end

        it 'gives Conflict if slug is taken' do
          post '/', graph.dump(:ttl), 
               'CONTENT_TYPE' => 'text/plain', 
               'Slug' => 'moomin'
          expect(last_response.status).to eq 409
        end
      end
    end

    describe 'PUT' do
      let(:graph) { RDF::Graph.new }

      context 'with existing resource' do
        before do
          post '/', graph.dump(:ttl), 
               'CONTENT_TYPE' => 'text/plain', 
               'Slug' => 'moomin'
        end

        it 'returns an etag' do
          put '/moomin', '', 'CONTENT_TYPE' => 'text/plain'
          expect(last_response.header['Etag']).to be_a String
        end
        
        it 'updates ETag' do
          get '/moomin'
          etag = last_response.header['Etag']
          graph << RDF::Statement(RDF::Node.new,
                                  RDF::DC.title,
                                  'moomin')
          put '/moomin', graph.dump(:ttl), 'CONTENT_TYPE' => 'text/turtle'
          expect(last_response.header['Etag']).not_to eq etag
        end
      end
    end
  end
end
