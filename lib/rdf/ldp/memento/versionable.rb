require 'rdf/ldp/memento/version_container'

module RDF::LDP::Memento
  ##
  # Mixin to `RDF::LDP::Resource` adding Memento versioning support. The 
  # interfaces implemented here are compatible with `Rack::Memento` and 
  # the fcrepo4 API Specification.
  # 
  # @see RDF::LDP::Resource
  # @see Rack::Memento
  module Versionable
    TIMEMAP_CONTAINER_CLASS = RDF::LDP::Memento::VersionContainer

    ##
    # @return []
    def timegate
      self
    end

    ##
    # @return [VersionContainer]
    def timemap
      @timemap ||= RDF::LDP::Resource.find(timemap_uri, @data)
    rescue RDF::LDP::NotFound
      @timemap = TIMEMAP_CONTAINER_CLASS.new(timemap_uri, @data)
    end
    alias_method :version_container, :timemap

    ##
    # Build a timemap uri
    #
    # @param uri [RDF::URI]
    def timemap_uri
      subject_uri / '.well-known/timemap'
    end
  end
end
