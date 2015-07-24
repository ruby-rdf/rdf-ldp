require 'link_header'

module RDF::LDP
  class Resource
    attr_reader :subject_uri
    attr_accessor :metagraph
                          
    class << self
      ##
      # @return [RDF::URI] uri with lexical representation 
      #   'http://www.w3.org/ns/ldp#Resource'
      #
      # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-resource
      def to_uri 
        RDF::Vocab::LDP.Resource
      end

      ##
      # Creates an unique id (URI Slug) for a resource.
      #
      # @note the current implementation uses {SecureRandom#uuid}.
      #
      # @return [String] a unique ID
      def gen_id
        SecureRandom.uuid
      end

      ##
      # Finds an existing resource and 
      # 
      # @param [RDF::URI] uri  the URI for the resource to be found
      # @param [RDF::Repository] data  a repostiory instance in which to find 
      #   the resource.
      #
      # @raise [RDF::LDP::NotFound] when the resource doesn't exist
      #
      # @return [RDF::LDP::Resource] a resource instance matching the given URI;
      #   usually of a subclass 
      #   from the interaction models.
      def find(uri, data)
        graph = RDF::Graph.new(uri / '#meta', data: data)
        raise NotFound if graph.empty?

        rdf_class = graph.query([uri, RDF.type, :o]).first
        klass = INTERACTION_MODELS[rdf_class.object] if rdf_class
        klass ||= RDFSource
        
        klass.new(uri, data) 
      end

      ##
      # Retrieves the correct interaction model from the Link headers.
      #
      # Headers are handled intelligently, e.g. if a client sends a request with
      # Resource, RDFSource, and BasicContainer headers, the server gives a 
      # BasicContainer. An error is thrown if the headers contain conflicting 
      # types (i.e. NonRDFSource and another Resource class).
      #
      # @param [String] link_header  a string containing Link headers from an 
      #   HTTP request (Rack env)
      # 
      # @return [Class] a subclass of {RDF::LDP::Resource} matching the 
      #   requested interaction model; 
      def interaction_model(link_header)
        models = LinkHeader.parse(link_header)
                 .links.select { |link| link['rel'].downcase == 'type' }
                 .map { |link| link.href }

        return RDFSource if models.empty?
        match = INTERACTION_MODELS.keys.reverse.find { |u| models.include? u }
        
        if match == RDF::LDP::NonRDFSource.to_uri
          raise NotAcceptable if 
            models.include?(RDF::LDP::RDFSource.to_uri) ||
            models.include?(RDF::LDP::Container.to_uri) ||
            models.include?(RDF::LDP::DirectContainer.to_uri) ||
            models.include?(RDF::LDP::IndirectContainer.to_uri) ||
            models.include?(RDF::URI('http://www.w3.org/ns/ldp#BasicContainer'))
        end

        INTERACTION_MODELS[match] || RDFSource
      end
    end

    def initialize(subject_uri, data = RDF::Repository.new)
      @subject_uri = RDF::URI(subject_uri)
      @data = data
      @metagraph = RDF::Graph.new(metagraph_name, data: data)
      yield self if block_given?
    end

    ##
    # @abstract creates the resource
    #
    # @param [IO, File, #to_s] input  input (usually from a Rack env's 
    #   `rack.input` key) used to determine the Resource's initial state.
    # @param [#to_s] content_type  a MIME content_type used to interpret the
    #   input. This MAY be used as a content type for the created Resource 
    #   (especially for `LDP::NonRDFSource`s).
    #
    # @raise [RDF::LDP::RequestError] when creation fails. May raise various 
    #   subclasses for the appropriate response codes.
    #
    # @return [RDF::LDP::Resource] self
    def create(input, content_type)
      raise Conflict if exists?
      metagraph << RDF::Statement(subject_uri, RDF.type, self.class.to_uri)
      self
    end

    ##
    # @abstract update the resource
    #
    # @param [IO, File, #to_s] input  input (usually from a Rack env's 
    #   `rack.input` key) used to determine the Resource's new state.
    # @param [#to_s] content_type  a MIME content_type used to interpret the
    #   input.
    #
    # @raise [RDF::LDP::RequestError] when update fails. May raise various 
    #   subclasses for the appropriate response codes.
    #
    # @return [RDF::LDP::Resource] self
    def update(input, content_type)
      raise NotImplementedError
    end

    ##
    # @abstract mark the resource as deleted
    #
    # @raise [RDF::LDP::RequestError] when delete fails. May raise various 
    #   subclasses for the appropriate response codes.
    #
    # @return [RDF::LDP::Resource] self
    def destroy
      raise NotImplementedError
    end

    ##
    # @return [Boolean] true if the resource exists within the repository
    def exists?
      @data.has_context? metagraph.context
    end

    ##
    # @return [Array<Symbol>] a list of HTTP methods allowed by this resource.
    def allowed_methods
      [:GET, :POST, :PUT, :DELETE, :PATCH, :OPTIONS, :HEAD].select do |m| 
        respond_to?(m.downcase, true)
      end
    end

    ##
    # @return [Boolean] whether this is an ldp:Resource
    def ldp_resource?
      true
    end

    ##
    # @return [Boolean] whether this is an ldp:Container
    def container?
      false
    end

    ##
    # @return [Boolean] whether this is an ldp:NonRDFSource
    def non_rdf_source?
      false
    end

    ##
    # @return [Boolean] whether this is an ldp:RDFSource
    def rdf_source?
      false
    end

    ##
    # Runs the request and returns the object's desired HTTP response body, 
    # conforming to the Rack interfare. 
    #
    # @see http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body 
    #   for Rack body documentation
    def to_response
      []
    end
    alias_method :each, :to_response

    ##
    # Build the response for the HTTP `method` given.
    # 
    # The method passed in is symbolized, downcased, and sent to `self` with the
    # other three parameters.
    #
    # Request methods are expected to return an Array appropriate for a Rack
    # response; to return this object (e.g. for a sucessful GET) the response 
    # may be `[status, headers, self]`.
    #
    # If the method given is unimplemented, we understand it to require an HTTP 
    # 405 response, and throw the appropriate error.
    #
    # @param [#to_sym] method  the HTTP request method of the response; this 
    #   message will be downcased and sent to the object.
    # @param [Fixnum] status  an HTTP response code; this status should be sent 
    #   back to the caller or altered, as appropriate.
    # @param [Hash<String, String>] headers  a hash mapping HTTP headers 
    #   built for the response to their contents; these headers should be sent 
    #   back to the caller or altered, as appropriate.
    # @param [] env  the Rack env for the request
    #
    # @return [Array<Fixnum, Hash<String, String>, #each] a new Rack response 
    #   array.
    def request(method, status, headers, env)
      begin
        send(method.to_sym.downcase, status, headers, env)
      rescue NotImplementedError => e
        raise MethodNotAllowed, method 
      end
    end

    private

    ##
    # Generate response for GET requests. Returns existing status and headers, 
    # with `self` as the body.
    def get(status, headers, env)
      [status, update_headers(headers), self]
    end

    ##
    # Generate response for HEAD requsets. Adds appropriate headers and returns 
    # an empty body.
    def head(status, headers, env)
      [status, update_headers(headers), []]
    end

    ##
    # Generate response for OPTIONS requsets. Adds appropriate headers and 
    # returns an empty body.
    def options(status, headers, env)
      [status, update_headers(headers), []]
    end

    ##
    # @return [RDF::URI] the name for this resource's metagraph
    def metagraph_name
      subject_uri / '#meta'
    end

    ##
    # @param [Hash<String, String>] headers
    # @return [Hash<String, String>] the updated headers
    def update_headers(headers)
      headers['Link'] = 
        ([headers['Link']] + link_headers).compact.join(",")
      
      headers['Allow'] = allowed_methods.join(', ')
      headers['Accept-Post'] = accept_post if respond_to?(:post, true)

      headers['Etag'] ||= etag if respond_to?(:etag)
      headers
    end

    ##
    # @return [String] the Accept-Post headers
    def accept_post
      RDF::Reader.map { |klass| klass.format.content_type }.flatten.join(', ')
    end

    ##
    # @return [Array<String>] an array of link headers to add to the 
    #   existing ones
    #
    # @see http://www.w3.org/TR/ldp/#h-ldpr-gen-linktypehdr
    # @see http://www.w3.org/TR/ldp/#h-ldprs-are-ldpr
    # @see http://www.w3.org/TR/ldp/#h-ldpnr-type
    # @see http://www.w3.org/TR/ldp/#h-ldpc-linktypehdr
    def link_headers
      return [] unless is_a? RDF::LDP::Resource
      headers = [link_type_header(RDF::LDP::Resource.to_uri)]
      headers << link_type_header(RDF::LDP::RDFSource.to_uri) if rdf_source?
      headers << link_type_header(RDF::LDP::NonRDFSource.to_uri) if
        non_rdf_source?
      headers << link_type_header(container_class) if container?
      headers
    end
    

    def link_type_header(uri)
      "<#{uri}>;rel=\"type\""
    end
  end
end
