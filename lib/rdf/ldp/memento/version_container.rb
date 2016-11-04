require 'rack/memento/timemap'

module RDF::LDP::Memento
  ##
  # A specialized container storing versions of another LDP::Resource.
  #
  # A `VersionContainer` is both an `ldp:BasicContainer` and a Memento TimeMap.
  # Its members are the versions of the its Original Resource.
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
    # Sets the memento timegate resource
    # @param original [#to_uri]
    # @return [RDF::URI]
    def memento_timegate=(timegate)
      @memento_timegate = timegate.to_uri
    end
    
    ##
    # @return [RDF::Enumerable<RDF::URI>] uris of the versions
    def memento_versions
      containment_triples.objects
    end
  end
end
