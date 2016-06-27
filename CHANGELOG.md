0.7.0
-----
 - Changes handling of input streams to be compliant with Rack. Allows
   the server to run with `Rack::Lint` middleware. In the process, the
   `RDFSource` and `NonRDFSource` interfaces are changed to accept only
   IO-like objects conforming to Rack's input expectations. `String`
   objects are no longer handled.

0.6.0
-----
 - Upgrades to RDF.rb 2.0
 - Adds true transaction scopes for POST & PUT requests
 - Changes behavior of direct & indirect containers to add default
   required triples on creation if none are supplied in the request.
   
0.5.1
-----
 - Fixes inserted content relation interpretations.
 - Uses RDF::Graph#query for better perfomance on Direct & Indirect
 Containers
 
0.5.0
-----
 - Fixes error that caused resources to be misidentified when trailing
 slashes are present.
 - Returns a 500 error and a useful message when `last_modified` is
 missing.

0.4.0
-----
 - Adds Last-Modified and updates ETag strategy to weak etags based on
 that date.
 - Destroys resources with an internal `prov:invalidatedAtTime`.
 - Adds conditional GET support.
 - Handles RDFSource responses more efficiently, avoiding loading the
 graph for HEAD & OPTIONS requests.
 - More efficient update/delete with RDF::Transactions.
 - Uses default prefixes from RDF.rb in responses.

0.3.0
------
 - Adds LDP-NR support with basic file storage
 - Moves `Lamprey` to `RDF::Lamprey`
 - Adds server executable (`./bin/lamprey`)
 - Adds support for IndirectContainer
 - Develops HTTP PATCH support with LDPatch and SPARQL Update formats
 - Allows new resource creation with PUT in Lamprey
 - Improves handling of Rack input (avoids calling off-SPEC `#eof?`)
 
0.2.0 
------
 - Initial release
   - Supports LDP-RS, BasicContainer, and DirectContainer
   - Ships with a limited server "Lamprey"
   - Note: 0.1.0 was a gem containing only an `RDF::Vocabulary`, this
     has been moved to `rdf-vocab`
