module RDF::LDP
  class DirectContainer < Container
    def self.to_uri
      RDF::URI('http://www.w3.org/ns/ldp#DirectContainer')
    end
  end
end
