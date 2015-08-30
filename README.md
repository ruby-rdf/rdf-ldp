RDF::LDP
========

[![Build Status](https://travis-ci.org/ruby-rdf/rdf-ldp.svg?branch=develop)](https://travis-ci.org/ruby-rdf/rdf-ldp)

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

# At v0.3.0, and after, do:

gem install rdf-ldp
lamprey
```

An `ldp:BasicContainer` will be created at the address of your first
`GET` request. Note that if that request is made to the server root,
Sinatra will assume a trailing slash.

```bash
$ curl -i http://localhost:4567

HTTP/1.1 200 OK
Content-Type: text/turtle
Link: <http://www.w3.org/ns/ldp#Resource>;rel="type",<http://www.w3.org/ns/ldp#RDFSource>;rel="type",<http://www.w3.org/ns/ldp#BasicContainer>;rel="type"
Allow: GET, POST, PUT, DELETE, OPTIONS, HEAD
Accept-Post: application/n-triples, text/plain, application/n-quads, text/x-nquads, application/ld+json, application/x-ld+json, application/rdf+json, text/html, text/n3, text/rdf+n3, application/rdf+n3, application/rdf+xml, text/csv, text/tab-separated-values, application/csvm+json, text/turtle, text/rdf+turtle, application/turtle, application/x-turtle, application/trig, application/x-trig, application/trix
Etag: "1B2M2Y8AsgTpgAmY7PhCfg==0"
Vary: Accept
X-Content-Type-Options: nosniff
Server: WEBrick/1.3.1 (Ruby/2.1.0/2013-12-25)
Date: Mon, 27 Jul 2015 23:19:06 GMT
Content-Length: 0
Connection: Keep-Alive
```

Rack::LDP
==========

Setting up a Custom Server with Rackup
---------------------------------------

You can quickly create your own server with any framework supporting [Rack](https://github.com/rack/). The simplest way to do this is with [Rackup](https://github.com/rack/rack/wiki/(tutorial)-rackup-howto).

```ruby
# ./config.ru

require 'rack/ldp'

use Rack::LDP::ContentNegotiation
use Rack::LDP::Errors
use Rack::LDP::Responses
use Rack::LDP::Requests

app = proc do |env|
  # define interactions here; respond with instances of `RDF::LDP::Resource`
  # subclasses, as desired. They do the work, and `Rack::LDP` middleware
  # interprets their responses for the server.
  #
  # see app/lamprey.rb for examples in Sinatra.
end

run app
```

Compliance
----------

Current compliance reports for Lamprey are located in [/reports](reports/).
Reports are generated by the LDP test suite. To duplicate the results,
use the `testsuite` branch, which contains a work-around for
[w3c/ldp-testsuite#224](https://github.com/w3c/ldp-testsuite/issues/224).


License
========

This software is released under a public domain waiver (Unlicense).

  



