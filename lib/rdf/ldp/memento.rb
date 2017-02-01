require 'rdf/ldp/memento/versionable'

module RDF::LDP
  ##
  # Memento support for RDF::LDP based servers.
  #
  # @example setting up Memento support
  #   RDF::LDP::Memento.use_memento!
  module Memento
    ##
    # Setup Memento
    # @return [void]
    def use_memento!
      RDF::LDP::InteractionModel.register(VersionedSource, default: true)
    end
    module_function :use_memento!

    ##
    # A generic {RDF::LDP::RDFSource} with {RDF::LDP::Memento::Versionable} 
    # support.
    class VersionedSource < RDF::LDP::RDFSource
      include RDF::LDP::Memento::Versionable
    end
  end
end
