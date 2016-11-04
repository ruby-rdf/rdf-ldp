module Rack
  class Memento
    class LinkFormatBuilder
      attr_accessor :original, :timegate, :timemap, :versions

      ##
      # @param original  [#to_s]
      # @param timegate  [#to_s]
      # @param timemap   [#to_s]
      # @param versions  [Array<#to_s>]
      def initialize(original: nil, timemap: nil, timegate: nil, versions: [])
        @original  = original
        @timegate  = timegate
        @timemap   = timemap
        @versions  = versions
      end

      ##
      # @return [String]
      def build
        string = link_original
        string += ",\n#{link_timegate}" if timegate
        string
      end

      ##
      # @return [String] the string for the "original" link relation
      def link_original
        raise 'Can\'t build an "original" link relation; ' \
              "`#original' was #{original}" unless original
        link(original, "original")
      end

      ##
      # @return [String] the string for the "timegate" link relation
      def link_timegate
        raise 'Can\'t build an "timegate" link relation; ' \
              "`#original' was #{timegate}" unless timegate
        link(timegate, "timegate")
      end

      private

      def link(uri, rel, options = {})
        link = "<#{uri}>;rel=\"#{rel}\""
        options.each { |param, value| link << "\n;#{param}=\"#{value}\"" }

        link
      end
    end
  end
end
