LDP Implementation Overview
============================

4.2 Resource
------------

### 4.2.1 General

 - __4.2.1.1__: HTTP 1.1 is supported through Rack. Implementers can use
 Rackup, Sinatra, Rails, and other Rack-driven frameworks to fully support
 HTTP 1.1 in their servers.
 - __4.2.1.2__: Currently, LDP-RSs are supported. LDP-NR support is a work in
 progress. See: __4.4__ for details on the status of LDP-NR development. [TODO]
 - __4.2.1.3__: ETags are generated for all LDPRs and returned for all requests
 to the resource. The specifics of ETag handling for POST requests are a work in
 progress.
 - __4.2.1.4__: Link headers for the resquested resource are added by
 `Rack::LDP::Headers` middleware.
 - __4.2.1.5__: [NON-COMPLIANT] Relative URI resolution in RDF graphs is
 unimplemented. [TODO]
 - __4.2.1.6__: Constraints are published in the {CONSTRAINED_BY.md} file in
 this repository. Additional, implementation specific constraints should be
 published by the server implementer and added to the headers for the server.

### 4.2.2 HTTP GET

 - __4.2.2.1__: LDPRs support GET. Retrieving existing persisted resources
 is a work in progress. [TODO]
 - __4.2.2.2__: The "Allow" headers specified for OPTIONS are returned with
 all requests for a given resource; this is handeled by the `Rack::LDP::Headers`
 middleware.

### 4.2.3 HTTP POST

 - POST is supported for LDP Containers, constranits are published in
 {CONSTRAINED_BY.md}. See: __4.2.1.6__ for details.

### 4.2.4 HTTP PUT

 - PUT support is planned for future development. [TODO]

### 4.2.5 HTTP DELETE

 - DELETE support is planned for future development. [TODO]

### 4.2.6 HTTP HEAD

 - __4.2.6.1__: HEAD is supported. See: __4.2.2.2__ for details on HTTP headers.

### 4.2.7 HTTP PATCH

 - PATCH support is under consideration. Decisions about formats for PATCH have
 not yet been made. [TODO]

### 4.2.8 HTTP OPTIONS

 - __4.2.8.1__: OPTIONS is supported for all resources. 
 - __4.2.8.2__: See: __4.2.2.2__ for details on HTTP headers.

4.3 LDP RDFSource
------------------

### 4.3.1 General

 - __4.3.1.1__: Each LDP-RS is an LDPR as described in this reports description
 of __4.2__.
 - __4.3.1.2__: [IGNORING SHOULD] Enforcement of the presence rdf:type is left
 to the client and/or server implementer. This software does not add or manage
 rdf:type in its representations.
 - __4.3.1.3__: See: __4.3.1.2__.
 - __4.3.1.4__: See: __4.2.2.1__. Content negotiation for returned RDF
 representations is handled by `Rack::LDP::ContentNegotiation`, which inherits
 `Rack::LinkedData::ContentNegotiation`.
 - __4.3.1.5-6__: Vocabulary use is left to the client.
 - __4.3.1.7-9__: These are constraints on the client, not addressed by this
 software.
 - __4.3.1.10__: No specialized rules about update or graph contents are
 enforced by this software. It requires no inferencing.
 - __4.3.1.11-13__: These are constraints on the client, not addressed by this
 software.

### 4.3.2 HTTP GET

 - __4.3.2.1__: [UNKNOWN] The default return type is `text/turtle`. No testing
 has been performed for the tie breaks prescribed in this section. Content
 negotiation is handled by `Rack::LDP::ContentNegotiation`.
 - __4.3.2.2__: The default return type is `text/turtle`.
 - __4.3.2.3__: [UNKNOWN] Content negotiation for explicit `application/ld+json`
 requests is functional. No testing has been performed for the tie breaks prescribed
 in this section.

4.4 Non-RDFSource
------------------

### 4.4.1 General

 - __4.4.1.1__: Each LDP-NR is an LDPR as described in this reports description
 of __4.2__. LDP-NR persistence is a work in progress. [TODO]
 - __4.4.1.2__: See __4.2.1.4__.

5.2 Container
--------------

### 5.2.1 General

 - __5.2.1.1__: Each LDPC is an LDP-RS as described in this report's description
 of __4.2__.
 - __5.2.1.2-3__: rdf:type is left to the client and/or implementer.
 - __5.2.1.4__: Link headers for type are added for all Resources; See:
 __4.2.1.4__.
 - __5.2.1.5__: [IGNORING SHOULD] Client hints are unimplemented. [TODO]

### 5.2.2 HTTP GET

 - __5.2.2.1__: See: __4.3.2.1__.

### 5.2.3 HTTP POST
 - __5.2.3.1__: Server responds 201 unless an error is thrown while completing
 the POST.
 - __5.2.3.2__: Server adds a containment triple with predicate `ldp:contains`
 when POST is successful.
 - __5.2.3.3__: POSTing an LDP-NR results in an error. [TODO]
 - __5.2.3.4__: Honors LDP interaction models in HTTP Link headers. Requests
 without an interaction model specified are treated as requests to create an
 LDP-RS.
   - Interaction models are honored for all of LDP-RS, LDP-NR, LDPC, as well as
   Basic, Direct, and Indirect container types.
   - Requests for LDPRs are treated as LDP-RS. We read the specification as
   vague with respect to the clause about requested LDPR interaction model.
   This behavior represents our interpretation.
 - __5.2.3.5__: POST requests to create an LDP-RS accept all content types
 supported with an `RDF::Reader` in the `linkeddata` gem (including
 'text/turtle'). These requests are processed, but persistence is a work in
 progress. [TODO]
 - __5.2.3.6__: The server relies solely on the `Content-Type` headers to
 understand the format of posted graphs. Requests without a `Content-Type` (or
 body) will fail.
 - __5.2.3.7__: [NON-COMPLIANT] Null/Relative URL resolution is planned for
 future development.
 - __5.2.3.8__: Created resources are assigned UUID's with the container as
 the base URI when no Slug header is present.
 - __5.2.3.9__: No constraints on graph contents are imposed.
 - __5.2.3.10__: Slug headers are treated as non-negotiable requests to create
 a resource at [container-uri]/[Slug]. If a resource exists at that address the
 request will fail.
 - __5.2.3.11__: [NON-COMPLIANT] handling for uri reuse will be addressed with
 persistence and deletion. [TODO]
 - __5.2.3.12__: POST requests to create LDP-NRs currently fail. Support is
 planned for future development [TODO].
 - __5.2.3.13__: [NON-COMPLIANT] Accept-Post headers are missing. Inclusion is
 planned for future development. [TODO]
 - __5.2.3.14__: See: __5.2.3.5__.

### 5.2.4 HTTP PUT

 - __5.2.4.1__: PUT support is planned for future development. [TODO]
 - __5.2.4.2__: See: __5.2.4.1__.
 
### 5.2.5 HTTP DELETE

 - __5.2.5.1__: DELETE support is planned for future development. [TODO]
 - __5.2.5.2__:See: __5.2.5.1__.

### 5.2.6 HTTP HEAD

 - See: __4.2.6__

### 5.2.7 HTTP PATCH

 - See: __4.2.7__

### 5.2.8 HTTP OPTIONS

 - __5.2.8.1__: Requests to create LDP-NR resources currently fail. No related
 LDP-RSs exist. [TODO]

5.3 Basic Container
--------------------

### 5.3.1 General

 - __5.3.1.1__: Basic Containers are treated as an alias for Container. 

5.4 Direct Container
--------------------

Direct Container support is planned for future development. [TODO]

5.5 Indirect Container
-----------------------

Indirect Container support is planned for future development. [TODO]


Handling of Non-Normative Notes
================================

