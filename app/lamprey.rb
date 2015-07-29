require 'rack/ldp'
require 'sinatra/base'

class RDF::Lamprey < Sinatra::Base

  use Rack::LDP::ContentNegotiation
  use Rack::LDP::Errors
  use Rack::LDP::Responses
  use Rack::LDP::Requests

  repository = RDF::Repository.new

  get '/*' do
    RDF::LDP::Container.new(RDF::URI(request.url), repository)
      .create('', 'text/plain') if repository.empty?
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

  head '/*' do
    RDF::LDP::Resource.find(RDF::URI(request.url), repository)
  end

  delete '/*' do
    RDF::LDP::Resource.find(RDF::URI(request.url), repository)
  end

  run! if app_file == $0
end
