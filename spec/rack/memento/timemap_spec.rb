require 'rack/memento/timemap'

describe Rack::Memento::Timemap do
  subject        { klass.new }
  let(:uri)      { RDF::URI('http://example.org/moomin#timemap') }
  let(:original) { RDF::URI('http://example.org/moomin') }
  let(:timegate) { RDF::URI('http://example.org/moomin/timegate') }

  let(:klass) do 
    Class.new do 
      include Rack::Memento::Timemap

      def initialize
        @memento_original = RDF::URI('http://example.org/moomin')
        @memento_timegate = RDF::URI('http://example.org/moomin/timegate')
      end
      
      def to_uri
        RDF::URI('http://example.org/moomin#timemap')
      end

      def memento_versions
        [RDF::URI('')]
      end
    end
  end

  it_behaves_like 'a memento timemap'
end
