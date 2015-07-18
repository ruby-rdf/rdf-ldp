module RDF::LDP
  class Resource
    ##
    # @return [RDF::URI] uri with lexical representation 
    #   'http://www.w3.org/ns/ldp#Resource'
    #
    # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-resource
    def self.to_uri 
      RDF::URI 'http://www.w3.org/ns/ldp#Resource'
    end

    ##
    # @return [Boolean] whether this is an ldp:Resource
    def ldp_resource?
      true
    end

    ##
    # @return [Boolean] whether this is an ldp:Container
    def container?
      false
    end

    ##
    # @return [Boolean] whether this is an ldp:NonRDFSource
    def non_rdf_source?
      false
    end

    ##
    # @return [Boolean] whether this is an ldp:RDFSource
    def rdf_source?
      false
    end

    ##
    # @abstract Returns the object's desired HTTP response body, conforming to 
    # the Rack interfare. Implementations MUST NOT alter the state of the object
    #
    # @param [Symbol] method  a symbol representing the request method to get
    #   a response for. (default: :GET)
    #
    # @see http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body 
    #   for Rack body documentation
    def to_response(method = :GET)
      raise NotImplementedError
    end
  end
end
