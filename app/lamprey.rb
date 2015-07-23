require 'sinatra'
require 'rack/ldp'

use Rack::LDP::ContentNegotiation
use Rack::LDP::Errors
use Rack::LDP::Responses
use Rack::LDP::Requests
use Rack::LDP::Headers

repository = RDF::Repository.new

get '/*' do
  RDF::LDP::Container.new(RDF::URI(request.url), repository)
end

post '/' do
  RDF::LDP::Container.new(RDF::URI(request.url), repository)
end

# options '/*' do
# end

