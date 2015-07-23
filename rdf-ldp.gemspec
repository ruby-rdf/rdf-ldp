#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'rdf-ldp'
  gem.homepage           = 'http://ruby-rdf.github.com/'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'A Ruby LDP Server.'
  gem.description        = 'A Ruby LDP Server.'

  gem.authors            = ['Tom Johnson']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.md CHANGELOG.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.require_paths      = %w(lib, app)
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.9.2'
  gem.requirements               = []

  gem.add_runtime_dependency     'rack'
  gem.add_runtime_dependency     'rack-linkeddata'
  gem.add_runtime_dependency     'rdf', '~> 1.1'
  gem.add_runtime_dependency     'rdf-turtle', '~> 1.1'
  gem.add_runtime_dependency     'rdf-vocab'
  gem.add_runtime_dependency     'json-ld'
  gem.add_runtime_dependency     'sinatra'

  gem.add_runtime_dependency     'link_header'


  gem.add_development_dependency 'rdf-spec',    '~> 1.1', '>= 1.1.13'
  gem.add_development_dependency 'rdf-rdfxml',  '~> 1.1'
  gem.add_development_dependency 'rdf-rdfa',    '~> 1.1'
  gem.add_development_dependency 'rdf-xsd',     '~> 1.1'
  gem.add_development_dependency 'rest-client', '~> 1.7'
  gem.add_development_dependency 'rspec',       '~> 3.0'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'rspec-its',   '~> 1.0'
  gem.add_development_dependency 'webmock',     '~> 1.17'
  gem.add_development_dependency 'yard',        '~> 0.8'

  gem.post_install_message       = nil
end
