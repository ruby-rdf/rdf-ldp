RDF::LDP
========

[![Build Status](https://travis-ci.org/ruby-rdf/rdf-ldp.svg?branch=develop)](https://travis-ci.org/ruby-rdf/rdf-ldp)

__WORK IN PROGRESS__

This software ships with the following libraries:

  - `RDF::LDP` --- contains the domain model for LDP Resources.
  - `Rack::LDP` --- a suite of Rack middleware for creating LDP servers based on
  `RDF::LDP`.
  - Lamprey --- a basic LDP server implemented with `Rack::LDP`.

Lamprey
=======

Lamprey is a basic LDP server. To start it, use:

```
bundle exec ruby app/lamprey.rb
```

License
========

This software is released under a public domain waiver (Unlicense).

  



