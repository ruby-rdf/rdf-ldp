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
    # @param datetime [DateTime] default: now
    def create_version(datetime: DateTime.now)
      version_uri(datetime)

      version = self.class.new(version_uri(datetime), @data)

      version.create(StringIO.new, 'text/plain') do |transaction|
        timemap.add(version, transaction)
      end
    end

    ##
    # @return []
    def timegate
      self
    end

    ##
    # @return [VersionContainer]
    def timemap
      @timemap ||= map RDF::LDP::Resource.find(timemap_uri, @data)
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

    ##
    # Build a version uri
    #
    # @param uri [RDF::URI]
    def version_uri(datetime)
      subject_uri / '.well_known/version' / datetime.strftime('%Y%m%d%H%M%S%L')
    end

    ##
    # List the versions of this resource
    #
    # @return [Enumerable<RDF::LDP::Resource>]
    def versions
      timemap.memento_versions.map do |uri|
        RDF::LDP::Resource.find(uri, @data)
      end
    end
  end
end
