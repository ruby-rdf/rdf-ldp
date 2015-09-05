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
      statements = parse_graph(input, content_type) unless exists?
      super
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
      statements = parse_graph(input, content_type)
      super
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
      method = patch_types[env['CONTENT_TYPE']]

      raise UnsupportedMediaType unless method

      send(method, env['rack.input'], graph)
      set_last_modified
      [200, update_headers(headers), self]
    end
   
    ##
    # @return [Hash<String,Symbol>] a hash mapping supported PATCH content types
    #   to the method used to process the PATCH request
    def patch_types
      { 'text/ldpatch'              => :ld_patch,
        'application/sparql-update' => :sparql_update }
    end
   
    def ld_patch(input, graph)
      LD::Patch.parse(input).execute(graph)
    rescue LD::Patch::Error => e
      raise BadRequest, e.message
    end

    def sparql_update(input, graph)
      SPARQL.execute(input, graph, update: true)
    rescue SPARQL::MalformedQuery => e
      raise BadRequest, e.message
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
    # @param [IO, File, String] input  a (Rack) input stream IO object or String
    #   to parse
    # @param [#to_s] content_type  the content type for the reader
    #
    # @return [RDF::Enumerable] the statements in the resulting graph
    #
    # @raise [RDF::LDP::UnsupportedMediaType] if no appropriate reader is found
    #
    # @todo handle cases where no content type is given? Does RDF::Reader have 
    #   tools to help us here?
    #
    # @see http://www.rubydoc.info/github/rack/rack/file/SPEC#The_Input_Stream 
    #   for documentation on input streams in the Rack SPEC
    def parse_graph(input, content_type)
      reader = RDF::Reader.for(content_type: content_type.to_s)
      raise(RDF::LDP::UnsupportedMediaType, content_type) if reader.nil?
      input = input.read if input.respond_to? :read
      begin
        RDF::Graph.new << reader.new(input, base_uri: subject_uri)
      rescue RDF::ReaderError => e
        raise RDF::LDP::BadRequest, e.message
      end  
    end
  end
end
