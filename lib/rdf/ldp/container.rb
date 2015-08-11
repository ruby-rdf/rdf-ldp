module RDF::LDP
  ##
  # An LDP Basic Container. This also serves as a base class for other 
  # container types. Containers are implemented as `RDF::LDP::RDFSources` with
  # the ability to contain other resources.
  #
  # Containers respond to `#post`, allowing new resources to be added to them.
  # On the public interface (not running through HTTP/`#request`), this is 
  # supported by `#add` and `#remove`.
  #
  # Containers will throw errors when attempting to edit them in conflict with
  # LDP's restrictions on changing containment triples.
  #
  # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-container definition
  #   of LDP Container
  class Container < RDFSource
    ##
    # @return [RDF::URI] uri with lexical representation 
    #   'http://www.w3.org/ns/ldp#Container'
    def self.to_uri
      RDF::Vocab::LDP.Container
    end

    ##
    # @return [Boolean] whether this is an ldp:Container
    def container?
      true
    end

    ##
    # @return [RDF::URI] a URI representing the container type
    def container_class
      CONTAINER_CLASSES[:basic]
    end

    ##
    # @see RDFSource#create
    def create(input, content_type)
      super { |statements| validate_triples!(statements) }
    end
    
    ##
    # @see RDFSource#update
    def update(input, content_type)
      super { |statements| validate_triples!(statements) }
    end

    ##
    # Adds a member `resource` to the container. Handles containment and 
    # membership triples as appropriate for the container type.
    #
    # @param [RDF::Term] a new member for this container
    # @return [Container] self
    def add(resource)
      add_containment_triple(resource.to_uri)
    end

    ##
    # Removes a member `resource` from the container. Handles containment and
    # membership triples as appropriate for the container type.
    #
    # @param [RDF::Term] a new member for this container
    # @return [Container] self
    def remove(resource)
      remove_containment_triple(resource.to_uri)
    end

    ##
    # @return [RDF::Query::Enumerator] the containment triples
    def containment_triples
      graph.query([subject_uri, 
                   RDF::Vocab::LDP.contains, 
                   nil]).statements
    end

    ##
    # @param [RDF::Statement] statement
    #
    # @return [Boolean] true if the containment triple exists
    #
    # @todo for some reason `#include?` doesn't work! figure out why, this is 
    #   clumsy.
    def has_containment_triple?(statement)
      !(containment_triples.select { |t| statement == t }.empty?)
    end

    ##
    # Adds a containment triple for `resource` to the container's `#graph`.
    #
    # @param [RDF::Term] a new member for this container
    # @return [Container] self
    def add_containment_triple(resource)
      graph << make_containment_triple(resource)
      self
    end

    ##
    # Remove a containment triple for `resource` to the container's `#graph`.
    #
    # @param [RDF::Term] a member to remove from this container
    # @return [Container] self
    def remove_containment_triple(resource)
      graph.delete(make_containment_triple(resource))
      self
    end

    ##
    # @param [RDF::Term] a member for this container
    #
    # @return [RDF::URI] the containment triple
    def make_containment_triple(resource)
      RDF::Statement(subject_uri, RDF::Vocab::LDP.contains, resource)
    end

    private

    ##
    # Handles a POST request. Parses a graph in the body of `env` and treats all
    # statements in that graph (irrespective of any graph names) as constituting
    # the initial state of the created source.
    #
    # @raise [RDF::LDP::RequestError] when creation fails
    #
    # @return [Array<Fixnum, Hash<String, String>, #each] a new Rack response 
    #   array.
    def post(status, headers, env)
      klass = self.class.interaction_model(env.fetch('HTTP_LINK', ''))
      slug = env['HTTP_SLUG']
      slug = klass.gen_id if slug.nil? || slug.empty?
      raise NotAcceptable.new('Refusing to create resource with `#` in Slug') if 
        slug.include? '#'

      id = (subject_uri / slug).canonicalize

      created = klass.new(id, @data)
                .create(env['rack.input'], env['CONTENT_TYPE'])
      
      add(created)
      headers['Location'] = created.subject_uri.to_s
      [201, created.send(:update_headers, headers), created]
    end

    def validate_triples!(statements)
      existing_triples = containment_triples.to_a
      statements.query(subject: subject_uri, 
                       predicate: RDF::Vocab::LDP.contains) do |statement|
        existing_triples.delete(statement) do 
          raise Conflict.new('Attempted to write unacceptable LDP ' \
                             "containment-triple: #{statement}") 
        end
      end
      raise Conflict.new('Cannot remove containment triples in updates. ' \
                         "Attepted to remove #{existing_triples}") unless
        existing_triples.empty?
    end
  end
end
