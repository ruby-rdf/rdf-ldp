require 'spec_helper'

describe RDF::LDP::IndirectContainer do
  it_behaves_like 'an IndirectContainer'

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

  describe '#inserted_content_relation' do
    it 'defaults to ldp:MemberSubject' do
      expect(subject.inserted_content_relation)
        .to eq RDF::Vocab::LDP.MemberSubject
    end

    it 'inserts ldp:MemberSubject statement into graph when defaulting' do
      expect { subject.inserted_content_relation }
        .to change { subject.graph.statements }
             .to(contain_exactly(RDF::Statement(subject.subject_uri,
                                        RDF::Vocab::LDP.insertedContentRelation,
                                        RDF::Vocab::LDP.MemberSubject)))
    end
  end
end
