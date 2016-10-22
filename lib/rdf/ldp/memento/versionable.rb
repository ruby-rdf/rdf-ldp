module RDF::LDP::Memento
  ##
  # Mixin to `RDF::LDP::Resource` adding Memento versioning support. The 
  # interfaces implemented here are compatible with `Rack::Memento` and the fcrepo4 API Specification.
  # 
  # @see RDF::LDP::Resource
  # @see Rack::Memento
  module Versionable
    ##
    # @return []
    def timegate
      self
    end

    ##
    # @return [VersionContainer]
    # def timemap
    #
    # end
    # alias_method :version_container, :timemap
  end
end
