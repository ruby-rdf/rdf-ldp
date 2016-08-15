#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-ldp'
  gem.homepage           = 'http://ruby-rdf.github.com/'
  gem.license            = 'Unlicense'
  gem.summary            = 'A suite of LDP software and middleware for RDF.rb.'
  gem.description        = 'Implements a Linked Data Platform domain model, Rack ' \
                           'middleware for server implementers, and a simple ' \
                           'Sinatra-based server for RDF.rb'

  gem.authors            = ['Tom Johnson']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS CHANGELOG.md README.md IMPLEMENTATION.md UNLICENSE VERSION) + 
                           Dir.glob('lib/**/*.rb') + Dir.glob('app/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w(lamprey)
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib app)
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 2.2.2'
  gem.requirements               = []

  gem.add_runtime_dependency     'rack',            '~> 1.6'
  gem.add_runtime_dependency     'rdf',             '~> 2.0'
  gem.add_runtime_dependency     'rdf-turtle',      '~> 2.0'
  gem.add_runtime_dependency     'ld-patch',        '~> 0.3'
  gem.add_runtime_dependency     'rdf-vocab',       '~> 2.0'
  gem.add_runtime_dependency     'rack-linkeddata', '~> 2.0'

  gem.add_runtime_dependency     'json-ld', '~> 2.0'

  gem.add_runtime_dependency     'sinatra', '~> 1.4'

  gem.add_runtime_dependency     'link_header', '~> 0.0', '>= 0.0.8'

  gem.add_development_dependency 'rdf-spec',              '~> 2.0'
  gem.add_development_dependency 'rdf-rdfxml',            '~> 2.0'
  gem.add_development_dependency 'rdf-rdfa',              '~> 2.0'
  gem.add_development_dependency 'rdf-xsd',               '~> 2.0'
  gem.add_development_dependency 'rest-client',           '~> 1.7'
  gem.add_development_dependency 'rspec',                 '~> 3.0'
  gem.add_development_dependency 'rack-test',             '~> 0.6'
  gem.add_development_dependency 'rspec-its',             '~> 1.0'
  gem.add_development_dependency 'timecop',               '~> 0.8'
  gem.add_development_dependency 'webmock',               '~> 1.17'
  gem.add_development_dependency 'yard',                  '~> 0.8'

  gem.add_development_dependency 'faraday'
  gem.add_development_dependency 'capybara_discoball'
  gem.add_development_dependency 'ldp_testsuite_wrapper', '~> 0.0.4'

  gem.post_install_message       = nil
end
