require 'spec_helper'

require 'rdf/ldp/memento/version_container'

describe RDF::LDP::Memento::VersionContainer do
  subject        { described_class.new(uri) }
  let(:uri)      { RDF::URI('http://example.org/moomin/.well-known/timemap') }
  let(:original) { RDF::URI('http://example.org/moomin/') }

  before { subject.memento_original = original }
  
  it_behaves_like 'a memento timemap'
  it_behaves_like 'a Container'
end
