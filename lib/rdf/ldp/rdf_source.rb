module RDF::LDP
  class RDFSource < Resource
    ##
    # @return [RDF::URI] uri with lexical representation 
    #   'http://www.w3.org/ns/ldp#RDFSource'
    #
    # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-rdf-source
    def self.to_uri 
      RDF::URI 'http://www.w3.org/ns/ldp#RDFSource'
    end

    ##
    # @return [Boolean] whether this is an ldp:RDFSource
    def rdf_source?
      true
    end
  end
end
