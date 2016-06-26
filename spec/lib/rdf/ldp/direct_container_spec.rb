require 'spec_helper'

describe RDF::LDP::DirectContainer do
  it_behaves_like 'a DirectContainer'

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

  describe '#add' do
    let(:resource_uri) { RDF::URI('http://ex.org/too-ticky') }

    it 'raises an error if the membership resource does not exist' do
      expect { subject.add(resource_uri) }
        .to raise_error RDF::LDP::NotAcceptable
      expect(subject.containment_triples).to be_empty
    end

    context 'when the membership resource exists' do
      before { subject.create(StringIO.new, 'application/n-triples') }

      it 'adds membership triple to membership resource' do
        expect(subject.add(resource_uri).graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      it 'adds membership triple to custom membership resource' do
        repo = RDF::Repository.new
        subject = described_class.new(uri, repo)
        mem_rs = RDF::LDP::RDFSource.new(RDF::URI('http://ex.org/mymble'), 
                                         repo)

        g = RDF::Graph.new << RDF::Statement(subject.subject_uri,
                                             RDF::Vocab::LDP.membershipResource,
                                             mem_rs.subject_uri)

        subject.create(StringIO.new(g.dump(:ntriples)), 'application/n-triples')
        mem_rs.create(StringIO.new, 'application/n-triples')

        subject.add(resource_uri)

        expect(mem_rs.graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      it 'adds membership triple to membership resource with #fragment' do
        repo = RDF::Repository.new
        subject = described_class.new(uri, repo)

        mem_rs = subject.subject_uri / '#membership'
        g = RDF::Graph.new << RDF::Statement(subject.subject_uri,
                                        RDF::Vocab::LDP.membershipResource,
                                        mem_rs)

        subject.create(StringIO.new(g.dump(:ntriples)), 'application/n-triples')
        expect(subject.add(resource_uri).graph)
          .to have_statement subject.make_membership_triple(resource_uri)
      end

      context 'with multiple membership resources' do
        it 'raises an error' do
          subject.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.membershipResource,
                                          subject.subject_uri)
          subject.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.membershipResource,
                                          (subject.subject_uri / 'moomin'))

          expect { subject.add(resource_uri) }
            .to raise_error RDF::LDP::RequestError
          expect(subject.containment_triples).to be_empty
        end
      end

      context 'with multiple membership resources' do
        it 'raises an error' do
          subject.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.hasMemberRelation,
                                          RDF::Vocab::DC.creator)
          subject.graph << RDF::Statement(subject.subject_uri,
                                          RDF::Vocab::LDP.hasMemberRelation,
                                          RDF::Vocab::DC.contributor)

          expect { subject.add(resource_uri) }
            .to raise_error RDF::LDP::RequestError
          expect(subject.containment_triples).to be_empty
        end
      end
    end
  end
end
