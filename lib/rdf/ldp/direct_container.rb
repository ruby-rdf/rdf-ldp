module RDF::LDP
  class DirectContainer < Container
    def self.to_uri
      RDF::Vocab::LDP.DirectContainer
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
      RDF::Vocab::LDP.contains
    end
  end
end
