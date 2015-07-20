require 'digest/md5'

module RDF::LDP
  class RDFSource < Resource
    attr_accessor :graph, :subject_uri

    ##
    # @param [IO, File, String] graph  an input stream to parse
    # @param [#to_s] content_type  the content type for the reader
    #
    # @return [RDF::Graph]
    def self.parse_graph(graph, content_type)
      reader = RDF::Reader.for(content_type: content_type.to_s)
      raise(RDF::LDP::UnsupportedMediaType, content_type) if reader.nil?
      begin
        RDF::Graph.new << reader.new(graph)
      rescue RDF::ReaderError => e
        raise RDF::LDP::BadRequest, e.message
      end  
    end

    ##
    # @return [RDF::URI] uri with lexical representation 
    #   'http://www.w3.org/ns/ldp#RDFSource'
    #
    # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-rdf-source
    def self.to_uri 
      RDF::URI 'http://www.w3.org/ns/ldp#RDFSource'
    end

    def initialize(subject_uri = nil, graph = RDF::Graph.new, &block)
      @subject_uri = subject_uri
      @graph = graph

      yield self if block_given?
      self
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
    # @return [RDF::URI] the subject URI for this resource
    def to_uri
      subject_uri
    end

    def to_response
      graph
    end
  end
end
