module Rack
  class Memento
    ##
    # Mixin behavior for Memento TimeMaps
    #
    # Implementing classes are expected to provide a `@memento_original`
    # instance variable, a `#to_uri` method, and a `#versions` method returning
    # an enumerable of version uris.
    module Timemap
      # @!attribute [r] memento_original
      #   @return [RDF::URI] the uri identifying the original resource (URI-R)
      # @!attribute [r] to_uri
      #   @return [RDF::URI] the uri identifying this (TimeMap) resource
      attr_reader :memento_original

      ##
      # @return [#each] a Rack response suitable for `link-format`
      # @see http://www.ietf.org/rfc/rfc6690.txt for info about CoRE Link Format
      # def link_format
      # end

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
