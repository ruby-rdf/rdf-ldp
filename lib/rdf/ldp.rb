require 'rdf'
require 'rdf/vocab'

require 'rdf/ldp/resource'
require 'rdf/ldp/rdf_source'
require 'rdf/ldp/non_rdf_source'
require 'rdf/ldp/container'
require 'rdf/ldp/direct_container'
require 'rdf/ldp/indirect_container'

module RDF
  module LDP
    ##
    # Interaction models are in reverse order of preference for POST/PUT 
    # requests; e.g. if a client sends a request with Resource, RDFSource, and
    # BasicContainer headers, the server gives a basic container.
    INTERACTION_MODELS = {
      RDF::Vocab::LDP.Resource => RDF::LDP::RDFSource,
      RDF::LDP::RDFSource.to_uri => RDF::LDP::RDFSource,
      RDF::LDP::Container.to_uri => RDF::LDP::Container,
      RDF::URI('http://www.w3.org/ns/ldp#BasicContainer') => RDF::LDP::Container,
      RDF::LDP::DirectContainer.to_uri => RDF::LDP::DirectContainer,
      RDF::LDP::IndirectContainer.to_uri => RDF::LDP::IndirectContainer,
      RDF::LDP::NonRDFSource.to_uri => RDF::LDP::NonRDFSource
    }.freeze

    CONTAINER_CLASSES = { 
      basic:    RDF::Vocab::LDP.BasicContainer,
      direct:   RDF::LDP::DirectContainer.to_uri,
      indirect: RDF::LDP::IndirectContainer.to_uri
    }

    CONSTRAINED_BY = RDF::Vocab::LDP.constrainedBy

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
        uri = 
          'https://github.com/no-reply/rdf-ldp/blob/master/CONSTRAINED_BY.md'
        { 'Link' => "<#{uri}>;rel=#{CONSTRAINED_BY}" }
      end
    end

    class BadRequest < RequestError
      STATUS = 400
    end

    class NotFound < RequestError
      STATUS = 404
    end

    class MethodNotAllowed < RequestError
      STATUS = 405
    end

    class NotAcceptable < RequestError
      STATUS = 406
    end

    class Conflict < RequestError
      STATUS = 409
    end

    class UnsupportedMediaType < RequestError
      STATUS = 415
    end
  end
end
