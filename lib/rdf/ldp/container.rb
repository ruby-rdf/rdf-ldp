module RDF::LDP
  class Container < RDFSource
    CONTAINER_CLASSES = { 
      basic:    RDF::URI('http://www.w3.org/ns/ldp#BasicContainer'),
      direct:   RDF::URI('http://www.w3.org/ns/ldp#DirectContainer'),
      indirect: RDF::URI('http://www.w3.org/ns/ldp#IndirectContainer') }
                          
    ##
    # @return [RDF::URI] uri with lexical representation 
    #   'http://www.w3.org/ns/ldp#Container'
    def self.to_uri 
      RDF::URI 'http://www.w3.org/ns/ldp#Container'
    end

    ##
    # @return [Boolean] whether this is an ldp:Container
    def container?
      true
    end

    ##
    # @return [RDF::URI] a URI representing the container type
    def container_class
      CONTAINER_CLASSES[:basic]
    end
  end
end
