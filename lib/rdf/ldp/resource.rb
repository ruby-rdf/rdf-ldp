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
    # the Rack interfare.
    #
    # @see http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body 
    #   for Rack body documentation
    def to_response
      raise NotImplementedError
    end
  end
end
