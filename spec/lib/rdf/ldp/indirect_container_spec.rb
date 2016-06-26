require 'spec_helper'

describe RDF::LDP::IndirectContainer do
  it_behaves_like 'an IndirectContainer'

  let(:uri) { RDF::URI('http://ex.org/moomin') }
  subject { described_class.new(uri) }

  describe '#membership_constant_uri' do
    it 'defaults to #subject_uri' do
      subject.create(StringIO.new, 'application/n-triples')
      expect(subject.membership_constant_uri).to eq subject.subject_uri
    end
  end

  describe '#membership_predicate' do
    it 'defaults to ldp:member' do
      subject.create(StringIO.new, 'application/n-triples')
      expect(subject.membership_predicate).to eq RDF::Vocab::LDP.member
    end
  end

  describe '#inserted_content_relation' do
    it 'defaults to ldp:MemberSubject' do
      subject.create(StringIO.new, 'application/n-triples')
      expect(subject.inserted_content_relation)
        .to eq RDF::Vocab::LDP.MemberSubject
    end

    it 'inserts ldp:MemberSubject statement into graph when defaulting' do
      subject.create(StringIO.new, 'application/n-triples')
      expect(subject.inserted_content_relation)
        .to eq RDF::Vocab::LDP.MemberSubject
    end
  end
end
