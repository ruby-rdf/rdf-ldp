require 'sinatra'
require 'rack/ldp'

use Rack::LDP::ContentNegotiation
use Rack::LDP::Errors
use Rack::LDP::Responses
use Rack::LDP::Headers
use Rack::LDP::Requests

get '/*' do
  RDF::LDP::Container.new.tap { |c| c.subject_uri = RDF::URI(request.url) }
end

post '/' do
  RDF::LDP::Container.new.tap { |c| c.subject_uri = RDF::URI(request.url) }
end

# options '/*' do
# end

