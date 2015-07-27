module RDF::LDP
  class IndirectContainer < DirectContainer
    def self.to_uri
      RDF::Vocab::LDP.IndirectContainer
    end

    ##
    # @return [RDF::URI] a URI representing the container type
    def container_class
      CONTAINER_CLASSES[:indirect]
    end
  end
end
