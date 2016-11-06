require 'rdf/ldp/memento/version_container'

module RDF::LDP::Memento
  ##
  # Mixin to `RDF::LDP::Resource` adding Memento versioning support. The
  # interfaces implemented here are compatible with `Rack::Memento` and
  # the fcrepo4 API Specification.
  # 
  # @note At present, this doesn't support versioning for LDP-NR 
  #   (`RDF::LDP:NonRDFSource`) resources.
  #
  # @see RDF::LDP::Resource
  # @see Rack::Memento
  module Versionable
    CREATED_URI             = RDF::Vocab::DC.created.freeze
    REVISION_URI            = RDF::Vocab::PROV.wasRevisionOf.freeze
    TIMEMAP_CONTAINER_CLASS = RDF::LDP::Memento::VersionContainer

    ##
    # @todo move the revison/created statement logic to VersionContainer
    #
    # @param datetime [DateTime] the timestamp to use for the version. 
    #   default: now
    # @param transaction [RDF::Transaction] the transaction to use when 
    #   creating the version. If none is given, a new transaction is 
    #   created.
    # 
    # @raise [NotImplementedError] when trying to create a version of a 
    #   NonRDFSource. Support for this is expected in a future release.
    # @raise [ArgumentError] when passed a future datetime for the version
    def create_version(datetime: DateTime.now, transaction: nil)
      raise(NotImplementedError, 
            'LDP-NR (NonRDFSource) versioning is unsupported.') if 
        non_rdf_source?

      raise(ArgumentError, 
            "Attempted to create a version at future time: #{datetime}") if
        datetime > DateTime.now

      timemap # touch the timemap in case it doesn't exist

      version = self.class.new(version_uri(datetime), @data)

      transaction = transaction || @data.transaction(mutable: true)

      timemap.add(version, transaction)

      transaction.insert revision_statement(version)
      transaction.insert created_statement(version, datetime)
      transaction.insert(version_graph(version)) if rdf_source?

      transaction.execute

      version
    end

    ##
    # @return [RDF::LDP::Resource] a content-negotiable timegate for this
    #   resource. Default: self
    def timegate
      self
    end

    ##
    # @return [VersionContainer] An LDPC that acts as a version container and
    #   timegate for this resource
    def timemap
      @timemap ||= RDF::LDP::Resource.find(timemap_uri, @data)
    rescue RDF::LDP::NotFound
      @timemap = TIMEMAP_CONTAINER_CLASS.new(timemap_uri, @data)
      @timemap.create(StringIO.new, 'text/plain')
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

    private

    def revision_statement(version)
      [version.subject_uri, REVISION_URI, subject_uri,
       version.metagraph.graph_name]
    end

    def created_statement(version, datetime)
      [version.subject_uri, CREATED_URI, datetime,
       version.metagraph.graph_name]
    end

    def version_graph(version)
      version_graph = RDF::Graph.new(graph_name: version.subject_uri, 
                                     data: RDF::Repository.new)
      version_graph << graph

      version_graph
    end
  end
end
