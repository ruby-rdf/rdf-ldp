module RDF::LDP
  class DirectContainer < Container
    def self.to_uri
      RDF::Vocab::LDP.DirectContainer
    end
  end
end
