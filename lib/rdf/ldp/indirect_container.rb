module RDF::LDP
  class IndirectContainer < DirectContainer
    def self.to_uri
      RDF::Vocab::LDP.IndirectContainer
    end
  end
end
