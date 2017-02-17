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
      RDF::LDP::InteractionModel.register(VersionContainer)
    end
    module_function :use_memento!

    ##
    # A generic {RDF::LDP::RDFSource} with {RDF::LDP::Memento::Versionable} 
    # support.
    class VersionedSource < RDF::LDP::RDFSource
      include RDF::LDP::Memento::Versionable
      
      ##
      # Creates with a new version.
      #
      # @see RDF::LDP::RDFSource#create
      def create(*args, &block)
        super do |transaction|
          create_version(transaction: transaction)
          yield transaction if block_given?
        end
      end
      
      ##
      # Updates with a new version.
      #
      # @see RDF::LDP::RDFSource#update
      def update(*args, &block)
        super do |transaction|
          create_version(transaction: transaction)
          yield transaction if block_given?
        end
      end
    end
  end
end
