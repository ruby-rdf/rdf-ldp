# coding: utf-8
require 'spec_helper'

require 'rdf/ldp'
require 'rdf/ldp/memento'

RSpec::Matchers.define :be_memento_versionable do
  match do |actual|
    methods = actual.instance_methods
    methods.include?(:create_version) && methods.include?(:timegate)
  end

  failure_message do |actual|
    "expected that #{actual} would be a RDF::LDP::Memento::Versionable"
  end
end


describe RDF::LDP::Memento do
  after { RDF::LDP.reset_interaction_models! }

  describe '.use_memento!' do
    it 'sets up default interaction model' do
      expect { described_class.use_memento! }
        .to change { RDF::LDP::InteractionModel.default }
        .to be_memento_versionable
    end

    it 'sets up ldf:RDFSource interaction model' do
      expect { described_class.use_memento! }
        .to change { RDF::LDP::InteractionModel.for(RDF::Vocab::LDP.RDFSource) }
        .to be_memento_versionable
    end
  end
end

describe RDF::LDP::Memento::VersionedSource do
  subject { described_class.new(uri) }

  let(:uri) { RDF::URI('http://example.org/moomin') }

  it_behaves_like 'a versionable LDP-R'

  describe '#create' do
  end
end
