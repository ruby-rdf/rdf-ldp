require 'bundler/setup'
require 'rdf/isomorphic'
require 'linkeddata'
require 'rdf/ldp'
require 'rdf/spec'
require 'rdf/spec/matchers'

require 'rdf/ldp/spec'

Dir['./spec/support/**/*.rb'].each { |f| require f }

begin
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError
end

RSpec.configure do |config|
  config.include(RDF::Spec::Matchers)
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

def fixture_path(filename)
  File.join(File.dirname(__FILE__), 'data', filename)
end

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
