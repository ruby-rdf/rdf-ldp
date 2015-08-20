require 'digest/sha1'
require 'ld/patch'

module RDF::LDP
  ##
  # The base class for all directly usable LDP Resources that *are not* 
  # `NonRDFSources`. RDFSources are implemented as a resource with:
  #
  #   - a `#graph` representing the "entire persistent state"
  #   - a `#metagraph` containing internal properties of the RDFSource
  #
  # Persistence schemes must be able to reconstruct both `#graph` and 
  # `#metagraph` accurately and separately (e.g. by saving them as distinct
  # named graphs). Statements in `#metagraph` are considered canonical for the
  # purposes of server-side operations; in the `RDF::LDP` core, this means they
  # determine interaction model.
  #
  # Note that the contents of `#metagraph`'s are *not* the same as 
  # LDP-server-managed triples. `#metagraph` contains statements internal 
  # properties of the RDFSource which are necessary for the server's management
  # purposes, but MAY be absent from the representation of its state in `#graph`.
  # 
  # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-rdf-source definition 
  #   of ldp:RDFSource in the LDP specification
  class RDFSource < Resource
    
    # @!attribute [rw] graph
    #   a graph representing the current persistent state of the resource.
    attr_accessor :graph

    class << self
      ##
      # @return [RDF::URI] uri with lexical representation 
      #   'http://www.w3.org/ns/ldp#RDFSource'
      #
      # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-rdf-source
      def to_uri 
        RDF::Vocab::LDP.RDFSource
      end
    end

    ##
    # @see RDF::LDP::Resource#initialize
    def initialize(subject_uri, data = RDF::Repository.new)
      @graph = RDF::Graph.new(subject_uri, data: data)
      super
      self
    end

    ##
    # Creates the RDFSource, populating its graph from the input given
    #
    # @param [IO, File, #to_s] input  input (usually from a Rack env's 
    #   `rack.input` key) used to determine the Resource's initial state.
    # @param [#to_s] content_type  a MIME content_type used to read the graph.
    #
    # @yield gives the new contents of `graph` to the caller's block before 
    #   altering the state of the resource. This is useful when validation is
    #   required or triples are to be added by a subclass.
    # @yieldparam [RDF::Enumerable] the contents parsed from input.
    #
    # @raise [RDF::LDP::RequestError] 
    # @raise [RDF::LDP::UnsupportedMediaType] if no reader can be found for the 
    #   graph
    # @raise [RDF::LDP::BadRequest] if the identified reader can't parse the 
    #   graph
    # @raise [RDF::LDP::Conflict] if the RDFSource already exists
    #
    # @return [RDF::LDP::Resource] self
    def create(input, content_type, &block)
      super
      statements = parse_graph(input, content_type)
      yield statements if block_given?
      graph << statements
      self
    end

    ##
    # Updates the resource. Replaces the contents of `graph` with the parsed 
    # input.
    #
    # @param [IO, File, #to_s] input  input (usually from a Rack env's 
    #   `rack.input` key) used to determine the Resource's new state.
    # @param [#to_s] content_type  a MIME content_type used to interpret the
    #   input.
    #
    # @yield gives the new contents of `graph` to the caller's block before 
    #   altering the state of the resource. This is useful when validation is
    #   required or triples are to be added by a subclass.
    # @yieldparam [RDF::Enumerable] the triples parsed from input.
    #
    # @raise [RDF::LDP::RequestError] 
    # @raise [RDF::LDP::UnsupportedMediaType] if no reader can be found for the 
    #   graph
    #
    # @return [RDF::LDP::Resource] self
    def update(input, content_type, &block)
      return create(input, content_type) unless exists?
      statements = parse_graph(input, content_type)
      yield statements if block_given?
      graph.clear!
      graph << statements
      self
    end

    ##
    # Clears the graph and marks as destroyed.
    #
    # @see RDF::LDP::Resource#destroy
    def destroy
      @graph.clear
      super
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
      "\"#{Digest::SHA1.base64digest(subs)}#{graph.statements.count}\""
    end

    ##
    # @param [String] tag  a tag to compare to `#etag`
    # @return [Boolean] whether the given tag matches `#etag`
    # def match?(tag)
    #   return false unless tag.split('==').last == graph.statements.count.to_s
    # end

    ##
    # @return [Boolean] whether this is an ldp:RDFSource
    def rdf_source?
      true
    end

    ##
    # Returns the graph representing this resource's state, without the graph 
    # context.
    def to_response
      RDF::Graph.new << graph
    end

    private

    ##
    # Process & generate response for PUT requsets.
    #
    # @raise [RDF::LDP::UnsupportedMediaType] when a media type other than 
    #   LDPatch is used
    # @raise [RDF::LDP::BadRequest] when an invalid document is given
    def patch(status, headers, env)
      check_precondition!(env)
      raise UnsupportedMediaType unless env['CONTENT_TYPE'] == 'text/ldpatch'

      ld_patch(env['rack.input'], graph)
      [200, update_headers(headers), self]
    end

    def ld_patch(input, graph)
      begin
        LD::Patch.parse(input).execute(graph)
      rescue LD::Patch::Error => e
        raise BadRequest, e.message
      end
    end

    ##
    # Process & generate response for PUT requsets.
    def put(status, headers, env)
      check_precondition!(env)

      if exists?
        update(env['rack.input'], env['CONTENT_TYPE'])
        headers = update_headers(headers)
        [200, headers, self]
      else
        create(env['rack.input'], env['CONTENT_TYPE'])
        [201, update_headers(headers), self]
      end
    end

    ##
    # @param [Hash<String, String>] env  a rack env
    # @raise [RDF::LDP::PreconditionFailed]
    def check_precondition!(env)
      raise PreconditionFailed.new('Etag invalid') if 
        env.has_key?('HTTP_IF_MATCH') && !match?(env['HTTP_IF_MATCH'])
    end


    ##
    # Finds an {RDF::Reader} appropriate for the given content_type and attempts
    # to parse the graph string.
    #
    # @param [IO, File, String] graph  an input stream to parse
    # @param [#to_s] content_type  the content type for the reader
    #
    # @return [RDF::Enumerable] the statements in the resulting graph
    #
    # @raise [RDF::LDP::UnsupportedMediaType] if no appropriate reader is found
    #
    # @todo handle cases where no content type is given? Does RDF::Reader have 
    #   tools to help us here?
    def parse_graph(graph, content_type)
      reader = RDF::Reader.for(content_type: content_type.to_s)
      raise(RDF::LDP::UnsupportedMediaType, content_type) if reader.nil?
      begin
        RDF::Graph.new << reader.new(graph, base_uri: subject_uri)
      rescue RDF::ReaderError => e
        raise RDF::LDP::BadRequest, e.message
      end  
    end
  end
end
