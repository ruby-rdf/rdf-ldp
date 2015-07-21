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

    ##
    # Aliases #subject_uri
    # @return [RDF::URI] #subject_uri
    def membership_constant_uri
      subject_uri
    end

    ##
    # @return [RDF::URI] the membership predicate
    # @see http://www.w3.org/TR/ldp/#dfn-membership-predicate
    def membership_predicate
      RDF::URI('http://www.w3.org/ns/ldp#contains')
    end

    ##
    # @return [RDF::Query::Enumerator] the membership triples
    def membership_triples
      graph.query([membership_constant_uri, 
                   membership_predicate, 
                   nil]).statements
    end

    ##
    # Adds a membership triple for `resource` to the container's `#graph`.
    #
    # @param [RDF::Term] a new member for this container
    # @return [Container] self
    def add_membership_triple(resource)
      graph << make_membership_triple(resource)
      self
    end

    ##
    # @param [RDF::Term] a member for this container
    #
    # @return [RDF::URI] the membership triple
    def make_membership_triple(resource)
      RDF::Statement(subject_uri, membership_predicate, resource)
    end

    private
    
    def post(status, headers, env)
      id = subject_uri / SecureRandom.uuid
      
      created = RDFSource.new(id) do |resource|
        resource.graph << RDFSource.parse_graph(env['rack.input'], 
                                                env['CONTENT_TYPE'])
      end
      
      add_membership_triple(created)

      headers['Location'] = created.subject_uri.to_s
      [201, headers, created]
    end
  end
end
