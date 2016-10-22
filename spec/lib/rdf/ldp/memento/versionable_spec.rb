# coding: utf-8
require 'rdf/ldp'
require 'rdf/ldp/memento/versionable'

describe RDF::LDP::Memento::Versionable do
  subject   { resource_class.new(uri) }
  let(:uri) { 'http://example.org/moomin' }

  let(:resource_class) do
    Class.new(RDF::LDP::Resource) do
      include RDF::LDP::Memento::Versionable
    end
  end

  describe '#timegate' do
    it 'defaults to self' do
      expect(subject.timegate).to equal subject
    end
  end

  describe '#timemap' do
  end
end
