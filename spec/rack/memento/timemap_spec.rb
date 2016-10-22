require 'rack/memento/timemap'

describe Rack::Memento::Timemap do
  subject        { klass.new }
  let(:uri)      { RDF::URI('http://example.org/moomin#timemap') }
  let(:original) { RDF::URI('http://example.org/moomin') }

  let(:klass) do 
    Class.new do 
      include Rack::Memento::Timemap

      def initialize
        @memento_original = RDF::URI('http://example.org/moomin')
      end
      
      def to_uri
        RDF::URI('http://example.org/moomin#timemap')
      end
    end
  end

  it_behaves_like 'a memento timemap'
end
