RDF::LDP Server Constraints
===========================

The RDF::LDP library, middleware, and the Lamprey server are all works in progress. We will use this file to document constraints imposed by these systems as implementation progresses.

In the meanwhile: buyer beware.

RDF Types
---------

The `RDF::LDP` core does not set types for resources. Complying with [LDP 4.3.1.2](http://www.w3.org/TR/ldp/#h-ldprs-gen-atleast1rdftype) is left to the client (or the server implementer). Interaction models are expressed as Link headers, and the client may infer rdf:types in accordance with the specification.

Similarly, we do not enforce the recommendation of [LDP 5.2.1.3](http://www.w3.org/TR/ldp/#h-ldpc-nordfcontainertypes) for containers not to have type ` rdf:Bag`, `rdf:Seq` or `rdf:List`. This is left to the client (or server implementer) to manage.

POST/PUT Requests
------------------

### Interaction Models

The interaction model of created resources depends solely on the Link headers specified in the request. When no interaction model is given, or it is `ldp:Resource`, the resulting resource will have interaction model `ldp:RDFSource`.

Requests with conflicting Link headers (e.g. `ldp:Container` & `ldp:NonRDFSource`) are rejected with `406 NotAcceptable`.

### Slug Headers

Slugs are accepted to POST requests. Slugs are URL-encoded, and treated as a strong request to generate a URI of form [container-uri]/[url-encoded-Slug]. If there is already a resource at the requested address, the server will respond `409 Conflict`.

Empty strings are treated as if no Slug was given.

### Membership URI/Predicate

The LDP specification requires the presence of _exactly one_ membership-constant-uri and membership predicate for each Direct Container. We do not impose this requirement on creation or update of a container. Attempts to POST to a Direct Container missing one of these triples will cause the defaults to be added and used for that request. Attempts to POST to a Direct Container with more than one of either of these triples will fail with `Not Allowed`. The defaults are:

  - membership-constant-uri: the container itself as 
  - membership-predicate: `ldp:member`

We allow the user to edit the relevant triples at their own discretion (effectively changing the membership uri or predicate during the life of the container), but recommend that clients SHOULD NOT do so.

Named Graphs
-------------

Serializations supporting quads are allowed in POST and PUT requests. Graph names are ignored, and the file is treated as a single graph representing the resource. This behavior is seen as in compliance with [4.2.4.1](http://www.w3.org/TR/ldp/#h-ldpr-put-replaceall).

----

Linking to this document fulfills [Section 4.2.1.6](http://www.w3.org/TR/ldp#h-ldpr-gen-pubclireqs) of the LDP specification. Implementers are advised to create their own documents to clarify how these constraints effect their own services.
