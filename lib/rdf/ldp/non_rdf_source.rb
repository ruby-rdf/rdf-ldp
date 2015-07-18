module RDF::LDP
  class NonRDFSource < Resource
    ##
    # @return [RDF::URI] uri with lexical representation 
    #   'http://www.w3.org/ns/ldp#NonRDFSource'
    #
    # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-non-rdf-source
    def self.to_uri 
      RDF::URI 'http://www.w3.org/ns/ldp#NonRDFSource'
    end

    ##
    # @return [Boolean] whether this is an ldp:NonRDFSource
    def non_rdf_source?
      true
    end
  end
end
