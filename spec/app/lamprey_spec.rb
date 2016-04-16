require 'spec_helper'
require 'rack/test'

require 'lamprey'

describe 'lamprey' do
  include ::Rack::Test::Methods
  let(:app) { RDF::Lamprey }
  
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
                                  RDF::Vocab::DC.title,
                                  'mummi')
          
          graph_str = graph.dump(:ntriples)

          post '/', graph_str, 'CONTENT_TYPE' => 'application/n-triples'
          @uri = last_response.header['Location']
        end
        
        it 'can get the resource' do
          get @uri
          returned = RDF::Reader.for(:ttl).new(last_response.body).statements.to_a

          graph.statements.each do |s|
            expect(returned).to include s
          end
        end

        it 'gets json-ld' do
          get @uri, '', 'HTTP_ACCEPT' => 'application/ld+json'
          returned = RDF::Reader.for(:jsonld).new(last_response.body).statements.to_a

          graph.statements.each do |s|
            expect(returned).to include s
          end
        end

        it 'is not a container' do
          get @uri
          expect(last_response.header['Link'])
            .not_to include 'http://www.w3.org/ns/ldp#BasicContainer'
        end

        it 'responds conditionally on ETag' do
          get @uri
          get @uri, '', 'HTTP_IF_NONE_MATCH' => last_response.header['ETag']

          expect(last_response.body).to be_empty
        end

        it 'responds conditionally on Last-Modified' do
          get @uri
          time = last_response.header['Last-Modified']
          get @uri, '', 'HTTP_IF_MODIFIED_SINCE' => time
                                                   
          expect(last_response.body).to be_empty
        end
      end
    end

    describe 'HEAD' do
      it 'responds to head' do
        head '/'
        expect(last_response.header['Allow'])
          .to include('GET', 'POST', 'OPTIONS', 'HEAD')
      end
    end

    describe 'OPTIONS' do
      it 'has Allow headers' do
        options '/'
        expect(last_response.header['Allow'])
          .to include('GET', 'POST', 'OPTIONS', 'HEAD', 'PATCH')
      end

      it 'has Accept-Post headers' do
        options '/'
        expect(last_response['Accept-Post']).to include 'text/turtle'
      end

      it 'has Accept-Patch headers' do
        options '/'
        expect(last_response['Accept-Patch']).to include 'text/ldpatch'
      end

      context 'existing resource' do
        before do
          post '/', '', 'CONTENT_TYPE' => 'application/n-triples', 'HTTP_SLUG' => 'moomin'
        end

        it 'has Allow for resource type' do
          options '/moomin'
          expect(last_response.header['Allow'])
            .to include('GET', 'OPTIONS', 'HEAD')
        end
      end
    end

    describe 'PATCH' do
      it 'returns 415 for unsupported media type' do
        patch '/', '', 'CONTENT_TYPE' => 'application/n-triples'
        expect(last_response.status).to eq 415
      end

      it 'returns 400 on improper document' do
        patch '/', '---blah---', 'CONTENT_TYPE' => 'text/ldpatch'
        expect(last_response.status).to eq 400
      end

      it 'returns 200 on valid LDPatch' do
        patch '/', '', 'CONTENT_TYPE' => 'text/ldpatch'
        expect(last_response.status).to eq 200
      end
    end

    describe 'POST' do
      let(:graph) { RDF::Graph.new }

      before do
        graph << RDF::Statement(RDF::URI('http://example.org/moomin'), 
                                RDF::Vocab::DC.title,
                                'mummi')
      end

      it 'gives a 201 status code' do
        post '/', graph.dump(:ttl), 'CONTENT_TYPE' => 'text/turtle'
        expect(last_response.status).to eq 201
      end

      it 'gives an ETag for the new resource' do
        post '/', graph.dump(:ttl), 'CONTENT_TYPE' => 'text/turtle'
        expect(last_response.status).to eq 201
      end

      it 'responds with the graph' do
        graph_str = graph.dump(:ntriples)
        post '/', graph_str, 'CONTENT_TYPE' => 'application/n-triples'
        returned = RDF::Reader.for(:ttl).new(last_response.body).statements.to_a

        graph.statements.each do |s|
          expect(returned).to include s
        end
      end

      it 'gives a location header' do
        post '/', graph.dump(:ttl), 'CONTENT_TYPE' => 'text/turtle'
        expect(last_response.header['Location'])
          .to start_with 'http://example.org/'
      end

      context 'with Slug' do
        it 'accepts a Slug' do
          post '/', graph.dump(:ttl), 
               'CONTENT_TYPE' => 'text/turtle', 
               'HTTP_SLUG' => 'moominpapa'
          expect(last_response.header['Location'])
            .to eq 'http://example.org/moominpapa'
        end

        it 'rejects slugs with #' do
          post '/', graph.dump(:ttl), 
               'CONTENT_TYPE' => 'text/turtle', 
               'HTTP_SLUG' => 'moomin#papa'
          expect(last_response.status).to eq 406
        end

        it 'gives Conflict if slug is taken' do
          post '/', graph.dump(:ttl), 
               'CONTENT_TYPE' => 'text/turtle', 
               'HTTP_SLUG' => 'moomin'
          expect(last_response.status).to eq 409
        end
      end
    end

    describe 'PUT' do
      let(:graph) { RDF::Graph.new }

      context 'with existing resource' do
        before do
          post '/', graph.dump(:ttl), 
               'CONTENT_TYPE' => 'text/turtle', 
               'HTTP_SLUG' => 'moomin'
        end

        it 'returns an etag' do
          put '/moomin', '', 'CONTENT_TYPE' => 'text/turtle'
          expect(last_response.header['Etag']).to be_a String
        end
        
        it 'updates ETag' do
          get '/moomin'
          etag = last_response.header['Etag']
          graph << RDF::Statement(RDF::Node.new,
                                  RDF::Vocab::DC.title,
                                  'moomin')
          put '/moomin', graph.dump(:ttl), 'CONTENT_TYPE' => 'text/turtle'
          expect(last_response.header['Etag']).not_to eq etag
        end
      end
      
      context 'creating a resource' do
        it 'returns 201' do
          put '/put_source', '', 'CONTENT_TYPE' => 'text/turtle'
          expect(last_response.status).to eq 201
        end

        it 'creates an RDFSource' do
          put '/put_rdf_source', '', 'CONTENT_TYPE' => 'text/turtle'

          links = LinkHeader.parse(last_response.header['Link']).links
          expect(links.map(&:href))
            .to contain_exactly(RDF::Vocab::LDP.Resource.to_s, 
                                RDF::Vocab::LDP.RDFSource.to_s)
                                                       
        end

        it 'creates an BasicContainer when using Container model' do
          put '/put_container', '', 'CONTENT_TYPE' => 'text/turtle', 
              'HTTP_LINK' => "#{RDF::Vocab::LDP.Container.to_base};rel=\"type\""

          links = LinkHeader.parse(last_response.header['Link']).links
          expect(links.map(&:href))
            .to include(RDF::Vocab::LDP.Resource.to_s, 
                        RDF::Vocab::LDP.RDFSource.to_s,
                        RDF::Vocab::LDP.BasicContainer.to_s)
        end

        it 'creates an BasicContainer when using BasicContainer model' do
          put '/put_container', '', 'CONTENT_TYPE' => 'text/turtle', 
              'HTTP_LINK' => "#{RDF::Vocab::LDP.BasicContainer.to_base};rel=\"type\""

          links = LinkHeader.parse(last_response.header['Link']).links
          expect(links.map(&:href))
            .to include(RDF::Vocab::LDP.Resource.to_s, 
                        RDF::Vocab::LDP.RDFSource.to_s,
                        RDF::Vocab::LDP.BasicContainer.to_s)
        end

        it 'creates an DirectContainer' do
          uri = RDF::Vocab::LDP.DirectContainer.to_base

          put '/put_direct_container', '', 'CONTENT_TYPE' => 'text/turtle', 
              'HTTP_LINK' => "#{uri};rel=\"type\""

          links = LinkHeader.parse(last_response.header['Link']).links
          expect(links.map(&:href))
            .to include(RDF::Vocab::LDP.Resource.to_s, 
                        RDF::Vocab::LDP.RDFSource.to_s,
                        RDF::Vocab::LDP.DirectContainer.to_s)
        end

        it 'creates an IndirectContainer' do
          uri = RDF::Vocab::LDP.IndirectContainer.to_base

          put '/put_indirect_container', '', 'CONTENT_TYPE' => 'text/turtle', 
              'HTTP_LINK' => "#{uri};rel=\"type\""

          links = LinkHeader.parse(last_response.header['Link']).links
          expect(links.map(&:href))
            .to include(RDF::Vocab::LDP.Resource.to_s, 
                        RDF::Vocab::LDP.RDFSource.to_s,
                        RDF::Vocab::LDP.IndirectContainer.to_s)
        end

        it 'creates a NonRDFSource' do
          uri = RDF::Vocab::LDP.NonRDFSource.to_base
          put '/put_nonrdf_source', '', 'CONTENT_TYPE' => 'text/turtle', 
              'HTTP_LINK' => "#{uri};rel=\"type\""

          links = LinkHeader.parse(last_response.header['Link']).links
            .select { |link| link.attr_pairs.first.include? 'type' }
          expect(links.map(&:href))
            .to contain_exactly(RDF::Vocab::LDP.Resource.to_s, 
                                RDF::Vocab::LDP.NonRDFSource.to_s)
                                                       
        end
      end
    end
    
    describe 'DELETE' do
    end
  end
end
