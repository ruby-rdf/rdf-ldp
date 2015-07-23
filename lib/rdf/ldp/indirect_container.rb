module RDF::LDP
  class IndirectContainer < Container
    def self.to_uri
      RDF::Vocab::LDP.IndirectContainer
    end
  end
end
