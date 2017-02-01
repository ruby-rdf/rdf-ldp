require 'spec_helper'

describe RDF::LDP do
  it 'has default interaction models' do
    expect(RDF::LDP::InteractionModel.default).to eq RDF::LDP::RDFSource

    expect(RDF::LDP::InteractionModel.for(RDF::Vocab::LDP.RDFSource))
      .to eq RDF::LDP::RDFSource
    expect(RDF::LDP::InteractionModel.for(RDF::Vocab::LDP.BasicContainer))
      .to eq RDF::LDP::Container
    expect(RDF::LDP::InteractionModel.for(RDF::Vocab::LDP.DirectContainer))
      .to eq RDF::LDP::DirectContainer
    expect(RDF::LDP::InteractionModel.for(RDF::Vocab::LDP.IndirectContainer))
      .to eq RDF::LDP::IndirectContainer
    expect(RDF::LDP::InteractionModel.for(RDF::Vocab::LDP.NonRDFSource))
      .to eq RDF::LDP::NonRDFSource
  end

  describe '.reset_interaction_models!' do
    let(:source_class) { Class.new(RDF::LDP::RDFSource) }

    before { RDF::LDP::InteractionModel.register(source_class, default: true) }
    after  { RDF::LDP.reset_interaction_models! }
    
    it 'resets the interaction model' do
      expect { described_class.reset_interaction_models! }
        .to change { RDF::LDP::InteractionModel.default }
        .from(source_class).to(RDF::LDP::RDFSource)
    end
  end
end
