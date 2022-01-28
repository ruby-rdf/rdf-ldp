#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-ldp'
  gem.homepage           = 'https://github.com/ruby-rdf/rdf-ldp'
  gem.license            = 'Unlicense'
  gem.summary            = 'A suite of LDP software and middleware for RDF.rb.'
  gem.description        = 'Implements a Linked Data Platform domain model, ' \
                           'Rack middleware for server implementers, and a ' \
                           'simple Sinatra-based server for RDF.rb'
  gem.metadata           = {
    "documentation_uri" => "https://ruby-rdf.github.io/rdf-ldp",
    "bug_tracker_uri"   => "https://github.com/ruby-rdf/rdf-ldp/issues",
    "homepage_uri"      => "https://github.com/ruby-rdf/rdf-ldp",
    "mailing_list_uri"  => "https://lists.w3.org/Archives/Public/public-rdf-ruby/",
    "source_code_uri"   => "https://github.com/ruby-rdf/rdf-ldp",
  }

  gem.authors            = ['Tom Johnson']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS CHANGELOG.md README.md
                              IMPLEMENTATION.md UNLICENSE VERSION) +
                           Dir.glob('lib/**/*.rb') + Dir.glob('app/**/*.rb')
  gem.bindir             = 'bin'
  gem.executables        = %w(lamprey)
  gem.require_paths      = %w(lib app)

  gem.required_ruby_version      = '>= 2.6'
  gem.requirements               = []

  gem.add_runtime_dependency     'rack',            '~> 2.2'
  gem.add_runtime_dependency     'rdf',             '~> 3.2'
  gem.add_runtime_dependency     'rdf-turtle',      '~> 3.2'
  gem.add_runtime_dependency     'ld-patch',        '~> 3.2'
  gem.add_runtime_dependency     'rdf-vocab',       '~> 3.2'
  gem.add_runtime_dependency     'rack-linkeddata', '~> 3.1'

  gem.add_runtime_dependency     'json-ld',         '~> 3.2'

  gem.add_runtime_dependency     'sinatra',         '~> 2.1'

  gem.add_runtime_dependency     'link_header', '~> 0.0', '>= 0.0.8'

  gem.add_development_dependency 'rdf-spec',              '~> 3.2'
  gem.add_development_dependency 'rdf-rdfxml',            '~> 3.2'
  gem.add_development_dependency 'rdf-rdfa',              '~> 3.2'
  gem.add_development_dependency 'rdf-xsd',               '~> 3.2'
  gem.add_development_dependency 'rest-client',           '~> 2.1'
  gem.add_development_dependency 'rspec',                 '~> 3.10'
  gem.add_development_dependency 'rubocop',               '~> 1.23'
  gem.add_development_dependency 'rubocop-rspec',         '~> 2.6'
  gem.add_development_dependency 'rack-test',             '~> 1.1'
  gem.add_development_dependency 'rspec-its',             '~> 1.3'
  gem.add_development_dependency 'timecop',               '~> 0.9'
  gem.add_development_dependency 'webmock',               '~> 3.14'
  gem.add_development_dependency 'yard',                  '~> 0.9'

  gem.add_development_dependency 'faraday',               '~> 1.1'
  gem.add_development_dependency 'capybara_discoball',    '~> 0.1.0'
  gem.add_development_dependency 'ldp_testsuite_wrapper', '~> 0.0.4'

  gem.post_install_message = nil
end
