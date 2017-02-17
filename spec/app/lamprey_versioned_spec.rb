require 'spec_helper'
require 'rack/test'

require 'lamprey'

require 'rack/memento'
require 'rdf/ldp/memento'

describe 'Lamprey with Memento' do
  include ::Rack::Test::Methods
  let(:app) { Class.new(RDF::Lamprey) }

  before do
    RDF::LDP::Memento.use_memento!
    app.use Rack::Memento
  end
  
  after do
    RDF::LDP.reset_interaction_models!
    app.repository.clear
  end

  describe 'RDFSource' do
    describe 'creation' do
      let(:path) { '/moomin' }

      it 'creates a resource with a timegate' do
        put path, '', 'CONTENT_TYPE' => 'text/turtle'

        expect(last_response.header['Link'])
          .to include "#{Rack::Memento::TIMEGATE_REL}"
      end

      it 'creates a resource with a timemap' do
        put File.join(path, 'new'), '', 'CONTENT_TYPE' => 'text/turtle'
        
        expect(last_response.header['Link'])
          .to match /<([^>]*)>;rel="#{Rack::Memento::TIMEMAP_REL}"/
      end

      it 'responds to the timemap uri' do
        put path, '', 'CONTENT_TYPE' => 'text/turtle'

        timemap_uri = /<([^>]*)>;rel="#{Rack::Memento::TIMEMAP_REL}"/
          .match(last_response.header['Link'])[1]
        
        get RDF::URI(timemap_uri).path
        
        expect(last_response).to be_ok
      end
      
      it 'creates a version' do
        put path, '', 'CONTENT_TYPE' => 'text/turtle'

        timemap_uri = /<([^>]*)>;rel="#{Rack::Memento::TIMEMAP_REL}"/
          .match(last_response.header['Link'])[1]
        
        get RDF::URI(timemap_uri).path
        
        reader    = RDF::Reader.for(content_type: last_response.content_type)
        graph     = RDF::Graph.new << reader.new(last_response.body)
        solutions = graph
          .query(predicate: RDF::LDP::Memento::VersionContainer::REVISION_URI)

        expect(solutions.count).to eq 1
      end
    end

    describe 'update' do
      let(:path) { '/moomin_mama' }

      before do
        put path, '', 'CONTENT_TYPE' => 'text/turtle'
        put path, '', 'CONTENT_TYPE' => 'text/turtle' 
      end

      it 'adds a version' do
                timemap_uri = /<([^>]*)>;rel="#{Rack::Memento::TIMEMAP_REL}"/
          .match(last_response.header['Link'])[1]

        get RDF::URI(timemap_uri).path
         
        reader    = RDF::Reader.for(content_type: last_response.content_type)
        graph     = RDF::Graph.new << reader.new(last_response.body)
        solutions = graph
          .query(predicate: RDF::LDP::Memento::VersionContainer::REVISION_URI)

        expect(solutions.count).to eq 2
      end
    end
  end
end
