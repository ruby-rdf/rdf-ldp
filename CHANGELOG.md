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
