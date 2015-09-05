require 'link_header'

module RDF::LDP
  ##
  # The base class for all LDP Resources. 
  #
  # The internal state of a Resource is specific to a given persistent datastore
  # (an `RDF::Repository` passed to the initilazer) and is managed through an
  # internal graph (`#metagraph`). A Resource has:
  #
  #   - a `#subject_uri` identifying the Resource.
  #   - a `#metagraph` containing server-internal properties of the Resource.
  #
  # Resources also define a basic set of CRUD operations, identity and current 
  # state, and a `#to_response`/`#each` method used by Rack & `Rack::LDP` to 
  # generate an appropriate HTTP response body. 
  #
  # `#metagraph' holds internal properites used by the server. It is distinct 
  # from, and may conflict with, other RDF and non-RDF information about the 
  # resource (e.g. representations suitable for a response body). Metagraph 
  # contains a canonical `rdf:type` statement, which specifies the resource's 
  # interaction model. If the resource is deleted, a flag in metagraph 
  # indicates this.
  # 
  # The contents of `#metagraph` should not be confused with LDP 
  # server-managed-triples, Those triples are included in the state of the 
  # resource as represented by the response body. `#metagraph` is invisible to
  # the client except where a subclass mirrors its contents in the body.
  #
  # @example creating a new Resource
  #   repository = RDF::Repository.new
  #   resource = RDF::LDP::Resource.new('http://example.org/moomin', repository)
  #   resource.exists? # => false
  #
  #   resource.create('', 'text/plain')
  #
  #   resource.exists? # => true
  #   resource.metagraph.dump :ttl
  #   # => "<http://example.org/moomin> a <http://www.w3.org/ns/ldp#Resource> ."
  #
  # @see http://www.w3.org/TR/ldp/ for the Linked Data platform specification
  # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-resource for a 
  #   definition of 'Resource' in LDP
  class Resource
    # @!attribute [r] subject_uri
    #   an rdf term
    attr_reader :subject_uri

    # @!attribute [rw] metagraph
    #   a graph representing the server-internal state of the resource
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

    ##
    # @param [RDF::URI, #to_s] subject_uri  the uri that identifies the Resource
    # @param [RDF::Repository] data  the repository where the resource's RDF 
    #   data (i.e. `metagraph`) is stored; defaults to an in-memory 
    #   RDF::Repository specific to this Resource.
    #
    # @yield [RDF::Resource] Gives itself to the block
    #
    # @example 
    #   RDF::Resource.new('http://example.org/moomin')
    #
    # @example with a block
    #   RDF::Resource.new('http://example.org/moomin') do |resource| 
    #     resource.metagraph << RDF::Statement(...)
    #   end
    #
    def initialize(subject_uri, data = RDF::Repository.new)
      @subject_uri = RDF::URI(subject_uri)
      @data = data
      @metagraph = RDF::Graph.new(metagraph_name, data: data)
      yield self if block_given?
    end

    ##
    # @abstract creates the resource
    #
    # @param [IO, File] input  input (usually from a Rack env's 
    #   `rack.input` key) used to determine the Resource's initial state.
    # @param [#to_s] content_type  a MIME content_type used to interpret the
    #   input. This MAY be used as a content type for the created Resource 
    #   (especially for `LDP::NonRDFSource`s).
    #
    # @raise [RDF::LDP::RequestError] when creation fails. May raise various 
    #   subclasses for the appropriate response codes.
    # @raise [RDF::LDP::Conflict] when the resource exists
    #
    # @return [RDF::LDP::Resource] self
    def create(input, content_type)
      raise Conflict if exists?
      set_interaction_model
      set_last_modified
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
      return create(input, content_type) unless exists?
      set_last_modified
      self
    end

    ##
    # Mark the resource as destroyed.
    #
    # This adds a statment to the metagraph expressing that the resource has 
    # been deleted
    #
    # @return [RDF::LDP::Resource] self
    # 
    # @todo Use of owl:Nothing is probably problematic. Define an internal 
    # namespace and class represeting deletion status as a stateful property.
    def destroy
      containers.each { |con| con.remove(self) if con.container? }
      @metagraph << RDF::Statement(subject_uri, 
                                   RDF::PROV.invalidatedAtTime,
                                   DateTime.now)
      self
    end

    ##
    # @return [Boolean] true if the resource exists within the repository
    def exists?
      @data.has_context? metagraph.context
    end

    ##
    # @return [Boolean] true if resource has been destroyed
    def destroyed?
      times = @metagraph.query([subject_uri, RDF::PROV.invalidatedAtTime, nil])
      !(times.empty?)
    end

    ##
    # Returns an Etag. This may be a strong or a weak ETag.
    #
    # @return [String] an HTTP Etag 
    #
    # @note these etags are strong if (and only if) all software that updates
    #   the resource also updates the ETag
    #
    # @see http://www.w3.org/TR/ldp#h-ldpr-gen-etags  LDP ETag clause for GET
    # @see http://www.w3.org/TR/ldp#h-ldpr-put-precond  LDP ETag clause for PUT
    # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.3.3 
    #   description of strong vs. weak validators
    def etag
      return nil unless exists?
      "\"#{subject_uri}#{last_modified.iso8601(6)}\""
    end

    ##
    # @return [DateTime] the time this resource was last modified
    #
    # @todo handle cases where there is more than one RDF::DC.modified.
    #    check for the most recent date
    def last_modified
      results = @metagraph.query([subject_uri, RDF::DC.modified, :time])
      return nil if results.empty?
      results.first.object.object
    end

    ##
    # @param [String] tag  a tag to compare to `#etag`
    # @return [Boolean] whether the given tag matches `#etag`
    def match?(tag)
      tag == etag 
    end

    ##
    # @return [RDF::URI] the subject URI for this resource
    def to_uri
      subject_uri
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
    # @return [Array<RDF::LDP::Resource>] the container for this resource
    def containers
      @data.query([:s, RDF::Vocab::LDP.contains, subject_uri]).map do |st|
        RDF::LDP::Resource.find(st.subject, @data)
      end
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
    # @param [Hash] env  the Rack env for the request
    #
    # @return [Array<Fixnum, Hash<String, String>, #each] a new Rack response 
    #   array.
    def request(method, status, headers, env)
      raise Gone if destroyed?
      begin
        send(method.to_sym.downcase, status, headers, env)
      rescue NotImplementedError, NoMethodError => e
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
    # Process & generate response for DELETE requests.
    def delete(status, headers, env)
      [204, headers, destroy]
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
      headers['Accept-Post'] = accept_post   if respond_to?(:post, true)
      headers['Accept-Patch'] = accept_patch if respond_to?(:patch, true)

      tag = etag
      headers['ETag'] ||= tag if tag

      modified = last_modified
      headers['Last-Modified'] ||= modified if modified

      headers
    end

    ##
    # @return [String] the Accept-Post headers
    def accept_post
      RDF::Reader.map { |klass| klass.format.content_type }.flatten.join(', ')
    end

    ##
    # @return [String] the Accept-Patch headers
    def accept_patch
      respond_to?(:patch_types, true) ? patch_types.keys.join(',') : ''
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

    ##
    # @return [String] a string to insert into a Link header
    def link_type_header(uri)
      "<#{uri}>;rel=\"type\""
    end

    ##
    # Sets the last modified date/time to now
    def set_last_modified
      metagraph.update([subject_uri, RDF::DC.modified, DateTime.now])
    end

    ##
    # Sets the last modified date/time to the URI for this resource's class
    def set_interaction_model
      metagraph << RDF::Statement(subject_uri, RDF.type, self.class.to_uri)
    end
  end
end
