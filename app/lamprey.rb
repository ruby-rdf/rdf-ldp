require 'sinatra'
require 'rack/ldp'

use Rack::LDP::ContentNegotiation
use Rack::LDP::Errors
use Rack::LDP::Responses
use Rack::LDP::Requests
use Rack::LDP::Headers

repository = RDF::Repository.new
RDF::LDP::Container.new(RDF::URI('http://example.org/'), repository)
  .create('', 'text/plain')

get '/*' do
  RDF::LDP::Resource.find(RDF::URI(request.url), repository)
end

post '/*' do
  RDF::LDP::Resource.find(RDF::URI(request.url), repository)
end

put '/*' do
  RDF::LDP::Resource.find(RDF::URI(request.url), repository)
end

options '/*' do
  RDF::LDP::Resource.find(RDF::URI(request.url), repository)
end

