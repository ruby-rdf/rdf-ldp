require 'rack'
begin
  require 'linkeddata'
rescue LoadError => e
  require 'rdf/turtle'
  require 'json/ld'
end

require 'rack/linkeddata'
require 'rdf/ldp'

module Rack
  ##
  # Provides Rack middleware for handling Linked Data Platform  requirements
  # when passed {RDF::LDP::Resource} and its subclasses as response objects.
  #
  # Response objects that are not an {RDF::LDP::Resource} are passed over 
  # without alteration, allowing server implementers to mix LDP interaction
  # patterns with others on the same server.
  #
  # @see http://www.w3.org/TR/ldp/ the LDP specification
  module LDP
    ##
    #
    class Responses
      ##
      # @param  [#call] app
      def initialize(app)
        @app = app
      end

      ##
      # @todo handle If-Match
      def call(env)
        status, headers, response = @app.call(env)

        if response.is_a? RDF::LDP::Resource
          new_response = response.to_response(env['REQUEST_METHOD'].to_sym)
          response.close if response.respond_to? :close
          response = new_response
        end

        [status, headers, response]
      end
    end

    ##
    # Rack middleware for LDP responses
    #
    # @todo handle adding `constrainedBy` headers on errored requests.
    class Headers
      CONSTRAINED_BY = RDF::URI('http://www.w3.org/ns/ldp#constrainedBy').freeze

      LINK_LDPR =  "<#{RDF::LDP::Resource.to_uri}>;rel=\"type\"".freeze
      LINK_LDPRS = "<#{RDF::LDP::RDFSource.to_uri}>;rel=\"type\"".freeze
      LINK_LDPNR = "<#{RDF::LDP::NonRDFSource.to_uri}>;rel=\"type\"".freeze

      ##
      # @param  [#call] app
      def initialize(app)
        @app = app
      end

      ##
      # Handles a Rack protocol request. Adds headers as required by LDP.
      #
      # @param [Array] env  a rack env array
      # @return [Array]  a rack env array with added headers
      def call(env)
        status, headers, response = @app.call(env)
        return [status, headers, response] unless 
          response.is_a? RDF::LDP::Resource

        headers['Link'] = 
          ([headers['Link']] + link_headers(response)).compact.join("\n")

        etag = etag(response)
        headers['Etag'] ||= etag if etag
        
        [status, headers, response]
      end

      private

      ##
      # @param [Object] response
      # @return [String]
      def etag(response)
        return response.etag if response.respond_to? :etag
        nil
      end
      
      ##
      # @param [Object] response
      # @return [Array<String>] an array of link headers to add to the 
      #   existing ones
      #
      # @see http://www.w3.org/TR/ldp/#h-ldpr-gen-linktypehdr
      # @see http://www.w3.org/TR/ldp/#h-ldprs-are-ldpr
      # @see http://www.w3.org/TR/ldp/#h-ldpnr-type
      # @see http://www.w3.org/TR/ldp/#h-ldpc-linktypehdr
      def link_headers(response)
        return [] unless response.is_a? RDF::LDP::Resource
        headers = [LINK_LDPR]
        headers << LINK_LDPRS            if response.rdf_source?
        headers << LINK_LDPNR            if response.non_rdf_source?
        headers << ldpc_header(response) if response.container?
        headers
      end

      ##
      # Generates a Link header string according to the LDP Container class 
      # of the response parameter.
      #
      # @param [#container_class] a container
      # @return [String] the appropriate Link header text
      def ldpc_header(response)
        "<#{response.container_class}>;rel=\"type\""
      end
    end

    ##
    # Specializes {Rack::LinkedData::ContentNegotiation}, making the default 
    # return type 'text/turtle'
    class ContentNegotiation < Rack::LinkedData::ContentNegotiation
      def initialize(app, options = {})
        options[:default] ||= 'text/turtle'
        super
      end
    end
  end
end

