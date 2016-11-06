# coding: utf-8
require 'spec_helper'

require 'rdf/ldp'
require 'rdf/ldp/memento/versionable'

describe RDF::LDP::Memento::Versionable do
  let(:resource_class) do
    Class.new(RDF::LDP::Resource) { include RDF::LDP::Memento::Versionable }
  end

  subject   { resource_class.new(uri) }
  let(:uri) { 'http://example.org/moomin' }

  it_behaves_like 'a versionable LDP-R'

  describe '#timemap' do
    it 'has a .well-known uri' do
      expect(subject.timemap.to_uri.to_s).to include '.well-known/timemap'
    end
    
    it 'returns the same timemap repeatedly' do
      expect(subject.timemap).to equal subject.timemap
    end
  end
end
