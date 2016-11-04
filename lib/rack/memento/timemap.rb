require 'rack/memento/link_format_builder'

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
      # @!attribute [r] memento_timegate
      #   @return [RDF::URI] the uri identifying the timegate resource (URI-G)
      # @!attribute [r] to_uri
      #   @return [RDF::URI] the uri identifying this (TimeMap) resource
      attr_reader :memento_original, :memento_timegate

      ##
      # @return [#each] a Rack response suitable for `link-format` requests
      # @see http://www.ietf.org/rfc/rfc6690.txt for info about CoRE Link Format
      def link_format
        [link_format_string]
      end

      ##
      # @return [String] the uri identifying this resource in string form
      # @see #to_uri
      # @see RDF::URI#to_s
      def to_s
        to_uri.to_s
      end

      private
      
      def link_format_string
        builder = LinkFormatBuilder.new(original: memento_original)
        builder.timegate = memento_timegate unless memento_timegate.nil?

        builder.build
      end
    end
  end
end
