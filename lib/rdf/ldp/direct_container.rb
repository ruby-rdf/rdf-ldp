module RDF::LDP
  ##
  # An extension of `RDF::LDP::Container` implementing direct containment. 
  # This adds the concepts of a membership resource, predicate, and triples to 
  # the Basic Container's containment triples.
  #
  # When the membership resource is an `RDFSource`, the membership triple is 
  # added/removed from its graph when the resource created/deleted within the
  # container. When the membership resource is a `NonRDFSource`, the triple is 
  # added/removed on its description's graph instead.
  #
  # A membership constant URI and membership predicate MUST be specified as
  # described in LDP--exactly one of each. If none is given, we default to
  # the container itself as a membership resource and `ldp:member` as predicate.
  # If more than one of either is given, all `#add/#remove` (POST/DELETE) 
  # requests will fail.
  #
  # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-direct-container
  #   definition of LDP Direct Container
  class DirectContainer < Container
    def self.to_uri
      RDF::Vocab::LDP.DirectContainer
    end

    RELATION_TERMS = [RDF::Vocab::LDP.hasMemberRelation,
                      RDF::Vocab::LDP.isMemberOfRelation]

    ##
    # @return [RDF::URI] a URI representing the container type
    def container_class
      CONTAINER_CLASSES[:direct]
    end

    ##
    # Adds a member `resource` to the container. Handles containment and adds 
    # membership triple to the memebership resource.
    #
    # @see RDF::LDP::Container#add
    def add(resource, transaction = nil)
      target = transaction || graph
      process_membership_resource(resource) do |membership, quad, resource|
        super(resource, transaction)
        target = transaction || membership.graph
        target << quad
      end
      self
    end

    ##
    # Removes a member `resource` to the container. Handles containment and 
    # removes membership triple to the memebership resource.
    #
    # @see RDF::LDP::Container#remove
    def remove(resource, transaction = nil)
      process_membership_resource(resource) do |membership, quad, resource|
        super(resource, transaction)
        target = transaction || membership.graph
        target.delete(quad)
      end
      self
    end

    ##
    # Gives the membership constant URI. If none is present in the container 
    # state, we add the current resource as a membership constant.
    #
    # @return [RDF::URI] the membership constant uri for the container
    #
    # @raise [RDF::LDP::NotAcceptable] if multiple membership constant uris exist
    #
    # @see http://www.w3.org/TR/ldp/#dfn-membership-triples
    def membership_constant_uri
      statements = membership_resource_statements
      case statements.count
        when 0
          graph << RDF::Statement(subject_uri, 
                                  RDF::Vocab::LDP.membershipResource, 
                                  subject_uri)
          subject_uri
        when 1
          statements.first.object
        else
          raise NotAcceptable.new('An LDP-DC MUST have exactly ' \
                                  'one membership resource; found ' \
                                  "#{statements}.")
      end
    end

    ##
    # Gives the membership predicate. If none is present in the container 
    # state, we add the current resource as a membership constant.
    #
    # @return [RDF::URI] the membership predicate
    #
    # @raise [RDF::LDP::NotAcceptable] if multiple membership predicates exist
    #
    # @see http://www.w3.org/TR/ldp/#dfn-membership-predicate
    def membership_predicate
      statements = member_relation_statements
      case statements.count
      when 0
        graph << RDF::Statement(subject_uri, 
                                RELATION_TERMS.first, 
                                RDF::Vocab::LDP.member)
        RDF::Vocab::LDP.member
      when 1
        statements.first.object
      else
        raise NotAcceptable.new('An LDP-DC MUST have exactly ' \
                                'one member relation triple; found ' \
                                "#{statements.count}.")
      end
    end

    ##
    # @param [RDF::Term] resource  a member for this container
    #
    # @return [RDF::URI] the membership triple representing membership of the
    #   `resource` parameter in this container
    #
    # @see http://www.w3.org/TR/ldp/#dfn-membership-triples
    def make_membership_triple(resource)
      predicate = membership_predicate
      return RDF::Statement(membership_constant_uri, predicate, resource) if
        member_relation_statements.first.predicate == RELATION_TERMS.first
      RDF::Statement(resource, predicate, membership_constant_uri)
    end

    private
    
    def membership_resource_statements
      graph.query([subject_uri, RDF::Vocab::LDP.membershipResource, :o])
    end

    def member_relation_statements
      graph.statements.select do |st| 
        st.subject == subject_uri && RELATION_TERMS.include?(st.predicate)
      end
    end

    def membership_resource
      uri = membership_constant_uri
      uri = uri.fragment ? (uri.root / uri.request_uri) : uri
      resource = RDF::LDP::Resource.find(uri, @data)
      return resource.description if resource.non_rdf_source?
      resource
    end

    def process_membership_resource(resource, &block)
      statement = make_membership_triple(resource.to_uri)

      begin
        membership_rs = membership_resource
      rescue NotFound => e
        raise NotAcceptable.new('Membership resource ' \
                                "#{membership_constant_uri} does not exist")
      end

      statement.graph_name = membership_rs.subject_uri
      yield(membership_rs, statement, resource) if block_given?
    end
  end
end
