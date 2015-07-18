require 'digest/md5'

module RDF::LDP
  class RDFSource < Resource
    attr_accessor :graph

    def initialize(graph = RDF::Graph.new)
      @graph = graph
    end

    ##
    # @return [RDF::URI] uri with lexical representation 
    #   'http://www.w3.org/ns/ldp#RDFSource'
    #
    # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-rdf-source
    def self.to_uri 
      RDF::URI 'http://www.w3.org/ns/ldp#RDFSource'
    end

    ##
    # Returns an Etag. This may be a strong or a weak ETag.
    #
    # @return [String] an HTTP Etag 
    #
    # @note the current implementation is a naive one that combines a couple of 
    # blunt heurisitics. 
    # 
    # @todo add an efficient hash function for RDF Graphs to RDF.rb and use that
    #   here?
    #
    # @see http://ceur-ws.org/Vol-1259/proceedings.pdf#page=65 for a recent
    #   treatment of digests for RDF graphs
    #
    # @see http://www.w3.org/TR/ldp#h-ldpr-gen-etags  LDP ETag clause for GET
    # @see http://www.w3.org/TR/ldp#h-ldpr-put-precond  LDP ETag clause for PUT
    # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.3.3 
    #   description of strong vs. weak validators
    def etag
      subs = graph.subjects.map { |s| s.node? ? nil : s.to_s }
             .compact.sort.join()
      "#{Digest::MD5.base64digest(subs)}#{graph.statements.count}"
    end

    ##
    # @param [String] tag  a tag to compare to `#etag`
    # @return [Boolean] whether the given tag matches `#etag`
    def match?(tag)
      return false unless tag.split('==').last == graph.statements.count
      tag == etag
    end

    ##
    # @return [Boolean] whether this is an ldp:RDFSource
    def rdf_source?
      true
    end

    ##
    # @param [Symbol] method  a symbol representing the request method to get
    #   a response for. (default: :GET)
    def to_response(method = :GET)
      send(method.downcase.to_sym)
    end
    
    private

    # response methods

    def get
      graph
    end
  end
end
