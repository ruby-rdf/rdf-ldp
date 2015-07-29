module RDF::LDP
  class NonRDFSource < Resource
    # Use DC elements format
    FORMAT_TERM = RDF::DC11.format
    DESCRIBED_BY_TERM = RDF::URI('http://www.w3.org/2007/05/powder-s#describedby')
    
    ##
    # @return [RDF::URI] uri with lexical representation 
    #   'http://www.w3.org/ns/ldp#NonRDFSource'
    #
    # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-non-rdf-source
    def self.to_uri 
      RDF::Vocab::LDP.NonRDFSource
    end

    ##
    # @return [Boolean] whether this is an ldp:NonRDFSource
    def non_rdf_source?
      true
    end

    ##
    # @param [IO, File] input  input (usually from a Rack env's 
    #   `rack.input` key) that will be read into the NonRDFSource
    # @param [#to_s] c_type  a MIME content_type used as a content type
    #   for the created NonRDFSource
    #
    # @raise [RDF::LDP::RequestError] when saving the NonRDFSource
    #
    # @return [RDF::LDP::NonRDFSource] self
    #
    # @see RDF::LDP::Resource#create
    def create(input, c_type)
      storage.io { |io| IO.copy_stream(input.binmode, io) }
      super
      self.content_type = c_type
      RDFSource.new(description_uri, @data).create('', 'text/plain')
      self
    end

    ##
    # @see RDF::LDP::Resource#update
    def update(input, c_type)
      storage.io { |io| IO.copy_stream(input.binmode, io) }
      self.content_type = c_type
      self
    end

    ##
    # Deletes the LDP-NR contents from the storage medium and marks the 
    # resource as destroyed.
    #
    # @see RDF::LDP::Resource#destroy
    def destroy
      storage.delete
      super
    end

    def etag
      "#{Digest::SHA1.base64digest(storage.io.read)}"
    end

    ##
    # @return [RDF::URI] uri for this resource's associated RDFSource
    def description_uri
      subject_uri / '.well-known' / 'desc'
    end

    ##
    # @return [StorageAdapter] the storage adapter for this LDP-NR
    def storage
      @storage_adapter ||= StorageAdapter.new(self)
    end
    
    ##
    # Sets the MIME type for the resource in `metagraph`.
    #
    # @param [String] a string representing the content type for this LDP-NR.
    #   This SHOULD be a regisered MIME type.
    #
    # @return [StorageAdapter] the content type 
    def content_type=(content_type)
      metagraph.delete([subject_uri, FORMAT_TERM])
      metagraph << RDF::Statement(subject_uri, RDF::DC11.format, content_type)
    end
    
    ##
    # @return [StorageAdapter] this resource's content type 
    def content_type
      format_triple = metagraph.first([subject_uri, FORMAT_TERM, :format])
      format_triple.nil? ? nil : format_triple.object.object
    end

    ##
    # @return [#each] the response body. This is normally the StorageAdapter's 
    #   IO object in read and binary mode.
    def to_response
      destroyed? ? [] : storage.io
    end

    private 

    ##
    # Process & generate response for PUT requsets.
    def put(status, headers, env)
      raise PreconditionFailed.new('Etag invalid') if 
        env.has_key?('HTTP_IF_MATCH') && !match?(env['HTTP_IF_MATCH'])
      
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
    # @see RDF::LDP::Resource#update_headers
    def update_headers(headers)
      headers['Content-Type'] = content_type
      super
    end

    def link_headers
      super << "<#{description_uri}>;rel=\"describedBy\""
    end

    ##
    # StorageAdapters bundle the logic for mapping a `NonRDFSource` to a 
    # specific IO stream. Implementations must conform to a minimal interface:
    #
    #  - `#initailize` must accept a `resource` parameter. The input should be 
    #     a `NonRDFSource` (LDP-NR).
    #  - `#io` must yield and return a IO object in binary mode that represents 
    #    the current state of the LDP-NR.
    #    - If a block is passed to `#io`, the implementation MUST allow return a
    #      writable IO object and that anything written to the stream while 
    #      yielding is synced with the source in a thread-safe manner.
    #    - Clients not passing a block to `#io` SHOULD call `#close` on the 
    #      object after reading it. 
    #    - If the `#io` object responds to `#to_path` it MUST give the location
    #      of a file whose contents are identical the IO object's. This supports
    #      Rack's response body interface.
    #  - `#delete` remove the contents from the corresponding storage. This MAY
    #      be a no-op if is undesirable or impossible to delete the contents 
    #      from the storage medium.
    #
    # @see http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body 
    #   for details about `#to_path` in Rack response bodies.
    #
    # @example reading from a `StorageAdapter`
    #   storage = StorageAdapter.new(an_nr_source)
    #   storage.io.read # => [string contents of `an_nr_source`]
    #
    # @example writing to a `StorageAdapter`
    #   storage = StorageAdapter.new(an_nr_source)
    #   storage.io { |io| io.write('moomin')
    #
    # Beyond this interface, implementations are permitted to behave as desired.
    # They may, for instance, reject undesirable content or alter the graph (or 
    # metagraph) of the resource. They should throw appropriate `RDF::LDP` 
    # errors when failing to allow the middleware to handle response codes and 
    # messages.
    #
    # The base storage adapter class provides a simple File storage 
    # implementation.
    #
    # @todo check thread saftey on write for base implementation 
    class StorageAdapter
      STORAGE_PATH = '.storage'.freeze

      ##
      # Initializes the storage adapter.
      #
      # @param [NonRDFSource] resource
      def initialize(resource)
        @resource = resource
      end
      
      ##
      # Gives an IO object which represents the current state of @resource.
      # Opens the file for read-write (mode: r+), if it already exists; 
      # otherwise, creates the file and opens it for read-write (mode: w+).
      #
      # @yield [IO] yields a read-writable object conforming to the Ruby IO 
      #   interface for storage. The IO object will be closed when the block 
      #   ends.
      #
      # @return [IO] an object conforming to the Ruby IO interface
      def io(&block)
        FileUtils.mkdir_p(path_dir) unless Dir.exists?(path_dir)

        if block_given?
          mode = file_exists? ? 'r+b' : 'w+b'
          return File.open(path, mode, &block)
        end
        
        file_exists? ? File.open(path, 'rb') : StringIO.new('')
      end
      
      ##
      # @return [Boolean] 1 if the file has been deleted, otherwise false
      def delete
        return false unless File.exists?(path)
        File.delete(path) 
      end

      private 

      ##
      # @return [Boolean]
      def file_exists?
        File.exists?(path)
      end

      ##
      # Build the path to the file on disk.
      # @return [String]
      def path
        File.join(STORAGE_PATH, @resource.subject_uri.path)
      end

      ##
      # Build the path to the file's directory on disk
      # @return [String]
      def path_dir
        File.split(path).first
      end
    end
  end
end
