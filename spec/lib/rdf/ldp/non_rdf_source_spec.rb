require 'spec_helper'

describe RDF::LDP::NonRDFSource do
  it_behaves_like 'a NonRDFSource'

  subject   { described_class.new(uri) }
  let(:uri) { RDF::URI 'http://example.org/moomin' }

  describe '.to_uri' do
    it { expect(described_class.to_uri).to be_a RDF::URI }
  end

  describe '#ldp_resource?' do
    it { is_expected.to be_ldp_resource }
  end

  describe '#container?' do
    it { is_expected.not_to be_container }
  end

  describe '#rdf_source?' do
    it { is_expected.not_to be_rdf_source }
  end

  describe '#non_rdf_source?' do
    it { is_expected.to be_non_rdf_source }
  end

  describe `#destroy` do
    context 'when destroy fails at repository' do
      before do
        subject.create(StringIO.new(input), ctype)

        allow(subject.instance_variable_get('@data'))
          .to receive(:transaction).and_raise(message)
      end

      let(:ctype)   { 'application/y-triples' }
      let(:input)   { 'moomin' }
      let(:message) { 'fake resource error' }

      it 'leaves file on disk' do
        expect { subject.destroy }.to raise_error message

        expect(subject).not_to be_destroyed
        expect(subject.to_response.read).to eq input
      end
    end
  end
end
