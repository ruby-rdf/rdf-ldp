require 'spec_helper'

describe RDF::LDP::IndirectContainer do
  it_behaves_like 'a DirectContainer'

  let(:uri) { RDF::URI('http://ex.org/moomin') }
  subject { described_class.new(uri) }

  describe '#membership_constant_uri' do
    it 'defaults to #subject_uri' do
      expect(subject.membership_constant_uri).to eq subject.subject_uri
    end
  end

  describe '#membership_predicate' do
    it 'defaults to ldp:member' do
      expect(subject.membership_predicate).to eq RDF::Vocab::LDP.member
    end
  end
end
