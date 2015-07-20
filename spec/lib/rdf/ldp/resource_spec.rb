require 'spec_helper'

describe RDF::LDP::Resource do
  it_behaves_like 'a Resource' 

  describe '#container?' do
    it { is_expected.not_to be_container }
  end

  describe '#rdf_source?' do
    it { is_expected.not_to be_rdf_source }
  end

  describe '#non_rdf_source?' do
    it { is_expected.not_to be_non_rdf_source }
  end

  describe '#request' do
    context 'with :GET' do
      it 'echos the request' do
        expect(subject.request(:GET, 200, {'abc' => 'def'}, {}))
          .to eq [200, {'abc' => 'def'}, subject]
      end
    end
  end
end
