require 'rdf'

module RDF
  module LDP
    autoload :Resource,     'rdf/ldp/resource'
    autoload :RDFSource,    'rdf/ldp/rdf_source'
    autoload :NonRDFSource, 'rdf/ldp/non_rdf_source'
    autoload :Container,    'rdf/ldp/container'

    CONSTRAINED_BY = 
      RDF::URI.new('http://www.w3.org/ns/ldp#constrainedBy').freeze

    ##
    # A base class for HTTP request errors.
    #
    # This and its subclasses are caught and handled by Rack::LDP middleware.
    class RequestError < RuntimeError
      STATUS = 500

      def status
        self.class::STATUS
      end

      def headers
        {}
      end
    end

    class BadRequest < RequestError
      STATUS = 400
    end

    class MethodNotAllowed < RequestError
      STATUS = 405
    end

    class UnsupportedMediaType < RequestError
      STATUS = 415
    end
  end
end
