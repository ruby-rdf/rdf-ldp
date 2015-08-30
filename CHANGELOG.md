
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
