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
  # The suite can be mix-and-matched as needed. This allows easy swap in of 
  # custom handlers for parts of the behavior. It is recommended that you use
  # {Rack::LDP::ContentNegotiation}, {Rack::LDP::Errors}, and 
  # {Rack::LDP::Responses} as the outer three services. With these in place,
  # you can handle requests as needed in your application, giving responses
  # conforming to the core {RDF::LDP::Resource} interface.
  #
  # @example
  #   run Rack:;Builder.new do
  #     use Rack::LDP::ContentNegotiation
  #     use Rack::LDP::Errors
  #     use Rack::LDP::Responses
  #     # ...
  #   end
  # 
  # @see http://www.w3.org/TR/ldp/ the LDP specification
  module LDP

    ##
    # Catches and handles RequestErrors thrown by RDF::LDP
    class Errors
      ##
      # @param  [#call] app
      def initialize(app)
        @app = app
      end

      ##
      # Catches {RDF::LDP::RequestError} and its various subclasses, building an 
      # appropriate response 
      #
      # @param [Array] env  a rack env array
      # @return [Array]  a rack env array with added headers
      #
      # @todo handle adding `constrainedBy` headers on errored requests.
      def call(env)
        begin
          @app.call(env)
        rescue RDF::LDP::RequestError => err
          return [err.status, err.headers, [err.message]]
        end
      end
    end

    ##
    # Converts RDF::LDP::Resource} into appropriate responses
    class Responses
      ##
      # @param  [#call] app
      def initialize(app)
        @app = app
      end

      ##
      # Converts the response body from {RDF::LDP::Resource} form to a Graph
      def call(env)
        status, headers, response = @app.call(env)

        if response.is_a? RDF::LDP::Resource
          new_response = response.to_response
          response.close if response.respond_to? :close
          response = new_response
        end

        [status, headers, response]
      end
    end

    ##
    #
    class Requests
      ##
      # @param  [#call] app
      def initialize(app)
        @app = app
      end

      ##
      # Handles a Rack protocol request. Sends appropriate request to the 
      # object, alters response accordingly.
      #
      # @param [Array] env  a rack env array
      # @return [Array]  a rack env array with added headers
      def call(env)
        status, headers, response = @app.call(env)
        return [status, headers, response] unless
          response.is_a? RDF::LDP::Resource

        response
          .send(:request, env['REQUEST_METHOD'].to_sym, status, headers, env)
      end
    end

    ##
    # Rack middleware for LDP responses
    class Headers
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
          ([headers['Link']] + link_headers(response)).compact.join(",")
        
        headers['Allow'] = response.allowed_methods.join(', ')
        headers['Accept-Post'] = accept_post if 
          response.respond_to?(:post, true)

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
      # @return [String] the Accept-Post headers
      def accept_post
        RDF::Reader.map { |klass| klass.format.content_type }.flatten.join(', ')
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
