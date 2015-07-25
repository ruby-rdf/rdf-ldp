module RDF::LDP
  class DirectContainer < Container
    def self.to_uri
      RDF::Vocab::LDP.DirectContainer
    end

    RELATION_TERMS = [RDF::Vocab::LDP.hasMemberRelation,
                      RDF::Vocab::LDP.isMemberOfRelation]

    def add(resource)
      process_membership_resource(resource) do |membership, triple|
        super
        membership.graph << triple
      end
    end

    def remove(resource)
      process_membership_resource(resource) do |membership, triple|
        super
        membership.graph.delete(triple)
      end
    end

    ##
    # Aliases #subject_uri
    # @return [RDF::URI] #subject_uri
    def membership_constant_uri
      case membership_resource_statements.count
        when 0
          graph << RDF::Statement(subject_uri, 
                                  RDF::Vocab::LDP.membershipResource, 
                                  subject_uri)
          subject_uri
        when 1
          membership_resource_statements.first.object
        else
          raise NotAcceptable.new('An LDP-DC MUST have exactly ' \
                                  'one membership resource; found ' \
                                  "#{membership_resource_statements.count}.")
      end
    end

    ##
    # @return [RDF::URI] the membership predicate
    # @see http://www.w3.org/TR/ldp/#dfn-membership-predicate
    def membership_predicate
      case member_relation_statements.count
      when 0
        graph << RDF::Statement(subject_uri, 
                                RELATION_TERMS.first, 
                                RDF::Vocab::LDP.member)
        RDF::Vocab::LDP.member
      when 1
        member_relation_statements.first.object
      else
        raise NotAcceptable.new('An LDP-DC MUST have exactly ' \
                                'one member relation triple; found ' \
                                "#{member_relation_statements.count}.")
      end
    end

    ##
    # @param [RDF::Term] a member for this container
    #
    # @return [RDF::URI] the membership triple to be added to the 
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
      RDF::LDP::Resource.find(uri, @data)
    end

    def process_membership_resource(resource, &block)
      triple = make_membership_triple(resource)

      begin
        membership_rs = membership_resource
      rescue NotFound => e
        raise NotAcceptable.new('Membership resource ' \
                                "#{membership_constant_uri} does not exist")
      end

      yield(membership_resource, triple, resource) if block_given?

      self
    end
  end
end
