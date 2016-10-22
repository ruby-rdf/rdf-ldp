require 'rack/memento/timemap'

module RDF::LDP::Memento
  ##
  # A specialized container storing versions of another LDP::Resource.
  class VersionContainer < RDF::LDP::Container
    include Rack::Memento::Timemap
    ##
    # Sets the memento original resource
    # @param original [#to_uri]
    # @return [RDF::URI]
    def memento_original=(original)
      @memento_original = original.to_uri
    end
    
    ##
    # @note overrides `Rack::Memento::Timemap#to_uri` to reinstate `RDF::LDP::Resource` behavior
    # @see RDF::LDP::Resource#to_uri
    def to_uri
      subject_uri
    end
  end
end
