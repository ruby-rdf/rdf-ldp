module RDF::LDP
  class IndirectContainer < Container
    def self.to_uri
      RDF::URI('http://www.w3.org/ns/ldp#IndirectContainer')
    end
  end
end
