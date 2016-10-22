module Rack
  class Memento
    ##
    # Mixin behavior for Memento TimeMaps
    #
    # Implementing classes are expected to provide a `@memento_original` instance variable and a `#to_uri`.
    module Timemap
      # @!attribute [r] memento_original
      #   @return [RDF::URI] the uri identifying the original resource (URI-R)
      # @!attribute [r] to_uri
      #   @return [RDF::URI] the uri identifying this (TimeMap) resource
      attr_reader :memento_original

      ##
      # @return [String] the uri identifying this resource in string form
      # @see #to_uri
      # @see RDF::URI#to_s
      def to_s
        to_uri.to_s
      end
    end
  end
end
