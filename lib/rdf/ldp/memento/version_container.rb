require 'rack/memento/timemap'

module RDF::LDP::Memento
  ##
  # A specialized container storing versions of another LDP::Resource.
  #
  # A `VersionContainer` is both an `ldp:BasicContainer` and a Memento TimeMap.
  # Its members are the versions of the its Original Resource.
  class VersionContainer < RDF::LDP::DirectContainer
    include Rack::Memento::Timemap

    CREATED_URI  = RDF::Vocab::DC.created.freeze
    REVISION_URI = RDF::Vocab::PROV.wasRevisionOf.freeze

    ##
    # @return [RDF::URI]
    # @todo Pick a more permanent VersionContainer uri
    def self.to_uri
      RDF::URI.intern('https://ruby-rdf.github.io/rdf-ldp/VersionContainer')
    end

    ##
    # @todo: spec this behavior more clearly
    # @see RDF::LDP::DirectContainer#add
    def add(version, transaction = nil, datetime = DateTime.now)
      super(version, transaction) # super handles nil transaction case
      tx = transaction || @data.transaction(mutable: true)
      tx.insert [version.to_uri, CREATED_URI, datetime, subject_uri]

      tx.execute unless tx.equal? transaction
      self
    end

    ##
    # @todo: cleanup state
    def memento_original
      @memento_original ||= membership_constant_uri
    end

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

    private

    ##
    # Override RDF::LDP::DirectContainer's default membership resource to use 
    # the Memento Original Resource
    def default_membership_resource_statement
      RDF::Statement(subject_uri, MEMBERSHIP_RESOURCE_URI, memento_original)
    end

    ##
    # Override RDF::LDP::DirectContainer's default member relation to use 
    # prov:wasRevisionOf.
    def default_member_relation_statement
      RDF::Statement(subject_uri, RELATION_TERMS.last, REVISION_URI)
    end
  end
end
